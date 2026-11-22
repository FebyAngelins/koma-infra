"""Layanan API Modul 08 di ECS Fargate (stateless; pesanan diterbitkan ke topik SNS).

    python3 koma_layanan.py [--port 8080]

    GET  /health          {"status": "ok"}
    GET  /versi           versi image, peran, dan nama host (ID task)
    GET  /hitung?n=200000 kerja CPU (untuk menguji auto scaling)
    GET  /lambat?ms=300   menunda jawaban
    GET  /metrics         metrik format Prometheus
    POST /pesanan         menerima pesanan JSON dan menerbitkannya ke KOMA_TOPIK_ARN

Konfigurasi lewat environment: KOMA_VERSI (ditanam saat build image), KOMA_PERAN (bawaan
"api"), KOMA_TOPIK_ARN (diisi task definition). Kredensial AWS datang dari task role ECS lewat
boto3; layanan tidak menyimpan kunci apa pun.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import socket
import sys
import threading
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

POLA_ID = re.compile(r"^[A-Za-z0-9-]{1,64}$")


class Metrik:
    def __init__(self) -> None:
        self._kunci = threading.Lock()
        self.permintaan: dict[tuple[str, int], int] = {}
        self.pesanan_terbit = 0

    def catat(self, path: str, kode: int) -> None:
        with self._kunci:
            self.permintaan[(path, kode)] = self.permintaan.get((path, kode), 0) + 1

    def teks(self, versi: str, peran: str) -> str:
        with self._kunci:
            baris = ["# TYPE koma_info gauge", f'koma_info{{versi="{versi}",peran="{peran}"}} 1',
                     "# TYPE koma_http_requests_total counter"]
            baris += [f'koma_http_requests_total{{path="{p}",code="{k}"}} {n}'
                      for (p, k), n in sorted(self.permintaan.items())]
            baris += ["# TYPE koma_pesanan_terbit_total counter", f"koma_pesanan_terbit_total {self.pesanan_terbit}"]
            return "\n".join(baris) + "\n"


def siapkan_pesanan(data: dict) -> dict:
    """Lengkapi dan periksa pesanan sebelum diterbitkan. ValueError bila tidak sah."""
    if not isinstance(data, dict):
        raise ValueError("pesanan harus objek JSON")
    pesanan = dict(data)
    pesanan.setdefault("id_pesanan", "P-" + uuid.uuid4().hex[:12])
    pesanan.setdefault("dibuat", datetime.now(timezone.utc).isoformat())
    for k in ("gerai", "total"):
        if k not in pesanan:
            raise ValueError(f"field {k} wajib")
    if not POLA_ID.match(str(pesanan["id_pesanan"])):
        raise ValueError("id_pesanan hanya boleh huruf, angka, dan '-' (maks. 64)")
    return pesanan


class Penerbit:
    """Penerbit SNS yang dibuat sekali; klien boto3 aman dipakai banyak thread."""

    def __init__(self, topik_arn: str | None, klien=None) -> None:
        self.topik_arn = topik_arn
        self._klien = klien

    def terbitkan(self, pesanan: dict) -> str:
        if not self.topik_arn:
            raise OSError("KOMA_TOPIK_ARN belum diisi")
        if self._klien is None:
            import boto3  # hanya dimuat bila benar-benar menerbitkan

            self._klien = boto3.client("sns")
        r = self._klien.publish(TopicArn=self.topik_arn, Message=json.dumps(pesanan))
        return r["MessageId"]


def buat_handler(metrik: Metrik, versi: str, peran: str, penerbit: Penerbit):
    class Handler(BaseHTTPRequestHandler):
        server_version = "KomaLayanan"

        def log_message(self, fmt, *args):
            sys.stderr.write("%s %s\n" % (self.address_string(), fmt % args))

        def _kirim(self, kode: int, isi, tipe: str = "application/json") -> None:
            data = isi.encode() if isinstance(isi, str) else json.dumps(isi).encode()
            self.send_response(kode)
            self.send_header("Content-Type", tipe)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _layani(self, metode: str) -> None:
            url = urlparse(self.path)
            q = parse_qs(url.query)
            kode = 404
            try:
                if metode == "GET" and url.path == "/health":
                    kode = 200
                    self._kirim(kode, {"status": "ok"})
                elif metode == "GET" and url.path == "/versi":
                    kode = 200
                    self._kirim(kode, {"versi": versi, "peran": peran, "host": socket.gethostname()})
                elif metode == "GET" and url.path == "/hitung":
                    n = min(int(q.get("n", ["200000"])[0]), 5_000_000)
                    kode = 200
                    self._kirim(kode, {"n": n, "hasil": sum(i * i for i in range(n)) % 1_000_007})
                elif metode == "GET" and url.path == "/lambat":
                    ms = min(int(q.get("ms", ["300"])[0]), 10_000)
                    time.sleep(ms / 1000)
                    kode = 200
                    self._kirim(kode, {"status": "ok", "ms": ms})
                elif metode == "GET" and url.path == "/metrics":
                    kode = 200
                    self._kirim(kode, metrik.teks(versi, peran), "text/plain; version=0.0.4")
                elif metode == "POST" and url.path == "/pesanan":
                    panjang = int(self.headers.get("Content-Length") or 0)
                    pesanan = siapkan_pesanan(json.loads(self.rfile.read(panjang) or b"{}"))
                    mid = penerbit.terbitkan(pesanan)
                    with metrik._kunci:
                        metrik.pesanan_terbit += 1
                    kode = 202
                    self._kirim(kode, {"status": "diterbitkan", "id_pesanan": pesanan["id_pesanan"],
                                       "message_id": mid, "versi": versi})
                else:
                    self._kirim(kode, {"galat": "tidak ditemukan"})
            except (ValueError, json.JSONDecodeError) as exc:
                kode = 400
                self._kirim(kode, {"galat": str(exc) or "permintaan tidak sah"})
            except Exception as exc:  # topik tidak terjangkau, izin, dsb.
                kode = 503
                self._kirim(kode, {"galat": f"topik tidak tersedia: {exc.__class__.__name__}"})
            finally:
                if url.path != "/metrics":
                    metrik.catat(url.path, kode)

        def do_GET(self):
            self._layani("GET")

        def do_POST(self):
            self._layani("POST")

    return Handler


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Layanan API Modul 08")
    ap.add_argument("--port", type=int, default=8080)
    a = ap.parse_args(argv)
    versi = os.environ.get("KOMA_VERSI", "0.0.0")
    peran = os.environ.get("KOMA_PERAN", "api")
    penerbit = Penerbit(os.environ.get("KOMA_TOPIK_ARN") or None)
    srv = ThreadingHTTPServer(("0.0.0.0", a.port), buat_handler(Metrik(), versi, peran, penerbit))
    srv.daemon_threads = True
    print(f"koma_layanan versi {versi} di port {a.port}", file=sys.stderr)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

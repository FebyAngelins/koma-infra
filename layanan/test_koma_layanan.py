"""Uji layanan tanpa AWS:  python3 -m unittest discover -s layanan"""

import json
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

import koma_layanan as kl


class PenerbitPalsu:
    def __init__(self):
        self.terbit = []

    def publish(self, TopicArn, Message):
        self.terbit.append((TopicArn, json.loads(Message)))
        return {"MessageId": f"m-{len(self.terbit)}"}


class TestLayanan(unittest.TestCase):
    def setUp(self):
        self.sns = PenerbitPalsu()
        penerbit = kl.Penerbit("arn:aws:sns:ap-southeast-2:111122223333:koma-uji", klien=self.sns)
        self.srv = ThreadingHTTPServer(("127.0.0.1", 0), kl.buat_handler(kl.Metrik(), "8.0.0", "stabil", penerbit))
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()
        self.url = f"http://127.0.0.1:{self.srv.server_address[1]}"

    def tearDown(self):
        self.srv.shutdown()
        self.srv.server_close()

    def minta(self, jalur, data=None):
        req = urllib.request.Request(self.url + jalur, data=None if data is None else json.dumps(data).encode(),
                                     method="GET" if data is None else "POST")
        try:
            with urllib.request.urlopen(req, timeout=5) as r:
                return r.status, json.loads(r.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read())

    def test_health_versi_hitung(self):
        self.assertEqual(self.minta("/health"), (200, {"status": "ok"}))
        kode, isi = self.minta("/versi")
        self.assertEqual((kode, isi["versi"], isi["peran"]), (200, "8.0.0", "stabil"))
        self.assertEqual(self.minta("/hitung?n=1000")[0], 200)

    def test_pesanan_diterbitkan_dengan_id(self):
        kode, isi = self.minta("/pesanan", {"gerai": "G-01", "total": 25000})
        self.assertEqual(kode, 202)
        self.assertTrue(isi["id_pesanan"].startswith("P-"))
        topik, pesan = self.sns.terbit[0]
        self.assertTrue(topik.endswith("koma-uji"))
        self.assertEqual((pesan["gerai"], pesan["id_pesanan"]), ("G-01", isi["id_pesanan"]))
        self.assertIn("dibuat", pesan)

    def test_pesanan_tidak_sah_ditolak(self):
        self.assertEqual(self.minta("/pesanan", {"total": 1})[0], 400)
        self.assertEqual(self.minta("/pesanan", {"gerai": "G", "total": 1, "id_pesanan": "../x"})[0], 400)
        self.assertEqual(self.sns.terbit, [])

    def test_tanpa_topik_503(self):
        self.srv.RequestHandlerClass = kl.buat_handler(kl.Metrik(), "8.0.0", "stabil", kl.Penerbit(None))
        self.assertEqual(self.minta("/pesanan", {"gerai": "G", "total": 1})[0], 503)


if __name__ == "__main__":
    unittest.main()

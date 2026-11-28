# Catatan Bukti Modul 08 — Capstone Cloud-Native

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | k01 |
| Kasus | Klinik Sehat Lampung |
| Repo GitHub (pemilik/nama) | FebyAngelins/koma-infra |

## Catatan Persiapan

`koma` versi 3.7.0, region ap-southeast-2, akun `<akun>`. Izin pipeline M08 (dorong image ke ECR) ditambahkan di `stacks/m00-pipeline` lalu di-apply; tanpa itu run image pertama gagal `ecr:GetAuthorizationToken`. Verifier dosen menolak (403 Forbidden) di setiap `koma cek m08` sepanjang modul, sehingga potret tidak terbentuk; sesuai arahan dosen bukti diambil dari keluaran terminal, `.koma/*.json`, run Actions, dan CloudWatch.

Nilai kasus yang dipakai:
- C1: API pendaftaran/jadwal stateless dipisah dari inti RME; antrean untuk notifikasi dan hasil lab; worker notifikasi.
- C2: puncak pagi Senin 4,7×, musim MCU ±2.000 pasien/hari, pengingat dikirim pukul 18.00.
- C3: API 90 → 420 rps, worker 30.000 pesan/jam; rencana 24 server API dan 70 server cache.
- C4: fitur baru diuji di 2 klinik percontohan, ±5% lalu lintas, di luar puncak pagi.
- C5: cluster dipakai 5 tim dengan kuota yang sama dengan lab.
- C6: portal jadwal publik boleh di serverless; API rekam medis tidak boleh di serverless publik.
- O1: ketersediaan 99,95% (anggaran ±21,6 menit per bulan), galat ≤ 0,05%. E4: SLA 99,95%. E5: p95 < 500 ms.

## Catatan Bagian A — Registri dan Image

`stacks/m08-registri`: plan `2 to add` (repositori `koma-123450039-m08-api` dengan tag IMMUTABLE, scan on push, force_delete, dan lifecycle yang menyimpan 5 image terakhir), apply berhasil. PR #10 menggabungkan registri dan workflow `m08.yml` (uji unit, uji asap `docker run --read-only` dengan cek `/health` dan `/versi`, OIDC, tolak versi yang sudah ada, dorong).

Run image:
- 8.0.0: https://github.com/FebyAngelins/koma-infra/actions/runs/45036091216 — percobaan pertama gagal `ecr:GetAuthorizationToken` (izin pipeline belum di-apply), kedua `RepositoryNotFoundException` (registri baru di-plan, belum di-apply); setelah keduanya di-apply, rerun berhasil.
- 8.1.0: https://github.com/FebyAngelins/koma-infra/actions/runs/45043331445 — percobaan pertama gagal 429 saat menarik image dasar dari `public.ecr.aws`, rerun berhasil.
- 8.2.0: https://github.com/FebyAngelins/koma-infra/actions/runs/45048570130 — berhasil sekali jalan (00:17 WIB, 23-11).

Di akhir Tugas registri berisi tag `8.0.0`, `8.1.0`, `8.2.0`; tag tidak bisa ditimpa, sehingga image yang diuji di pipeline sama dengan yang dijalankan ECS.

## Catatan Bagian B — Layanan di ECS

Plan `stacks/m08-layanan`: `31 to add` (cluster, log group, role eksekusi dan role task, task definition, service, ALB, target group, security group, listener, dan modul pesanan SNS → SQS → Lambda → S3 dengan DLQ), apply selesai sekitar 22:37:55 WIB (22-11). `koma sehat` pertama timeout karena IP berganti; `cidr_saya` diperbarui ke `182.10.35.135/32` lalu di-apply.

```text
SEHAT setelah 0.5 detik: {'status': 'ok'}
  202  P-424b4a1b5c74  8.0.0
  202  P-c80b0de3ac87  8.0.0
  202  P-6f3d7deff702  8.0.0
Diterima layanan: 3 dari 3.
2026-11-22 22:48:14  155 arsip/2026-11-22/P-424b4a1b5c74.json
```

Ketiga pesanan sampai di bucket `koma-123450039-m08-prod-arsip-<akun>` dalam 1–2 detik. Potret 1: verifier 403.

## Catatan Bagian C — Skala Otomatis

`skala.tf`: target tracking CPU 50%, kapasitas 1–3 task, cooldown keluar 60 detik dan masuk 120 detik; plan `2 to add`.

Beban pertama (`/`, 22:51:10–22:55:24): 280 permintaan, 6 gagal, p50 505 ms, p95 15.523 ms, tetapi CPU hanya 23,9% lalu 4–9%, sehingga tidak ada scale-out; bebannya tertahan jaringan laptop, bukan CPU task.

Beban kedua (`/hitung?n=3000000`, 4 pekerja, 22:57:59–23:03:03): 191 permintaan, 5 gagal, p50 3.703 ms, p95 18.424 ms.

| Waktu (WIB) | Menit | CPU rata-rata | desired / running | Aktivitas |
|---|---|---|---|---|
| 22:58 | 0 | 86,4% | 1 / 1 | beban mulai |
| 22:59 | 1 | 87,2% | 1 / 1 | |
| 23:00 | 2 | 50,6% | 1 / 1 | |
| 23:01:47 | 3,8 | 76,1% | 1 / 1 | |
| 23:03:09 | 5,2 | 30,9% | 2 / 1 | "Setting desired count to 2." |
| 23:03:56 | 6,0 | — | 2 / 2 | task kedua sehat |
| 23:05:17 | 7,3 | — | 2 / 2 | beban sudah berhenti, belum turun (cooldown masuk) |

Potret 2: verifier 403.

## Catatan Bagian D — Canary dan Promosi

PR #11 menaikkan layanan ke 8.1.0 (`/versi` menambah `"fitur": "antrean-klinik-percontohan"`). Canary 20% di-apply 23:29:01 WIB dalam satu langkah:

```text
Sampel 276, gagal 5, jeda terpanjang 3.1 dtk, versi {'8.0.0': 245, '8.1.0': 26}, alih pada detik 106.0
```

Lima kegagalan (detik 76–92) muncul karena listener sudah 80/20 sebelum task canary sehat. Promosi 23:34:43 juga satu langkah (stabil 8.1.0 dan service canary dihapus sekaligus): probe 224 sampel, 33 gagal, jeda terpanjang 8,8 detik, dan penghapusan target group canary gagal `ResourceInUse` karena listener masih menunjuknya. Pulih dengan `aws elbv2 modify-listener` ke target group stabil lalu `tofu apply` (`0 add, 2 change, 1 destroy`); probe sesudahnya 113 sampel, 0 gagal, hanya 8.1.0. Pelajaran dicatat di K-08-001: canary dan promosi dua langkah, dan `create_before_destroy` pada target group. `tofu test`: 6 passed (termasuk `canary_dua_puluh_persen` dan empat uji penolakan). Potret 3 dan 4: verifier 403.

Canary 8.2.0 (Tugas butir 3): PR #12 menaikkan `layanan/VERSI` ke 8.2.0 dengan field `"pengingat": "18.00"` (C2), run image 45048570130 hijau. Langkah 1: `versi_canary = "8.2.0"`, `bobot_canary = 0`, apply `3 added, 1 changed`, target canary `healthy`. Percobaan probe pertama tidak sah: apply bobot 5 ternyata belum dijalankan (`No changes`), probe 554 sampel, 29 gagal, 0 jawaban 8.2.0; kegagalannya timeout dari beban `--paralel 4` dan jaringan laptop. Langkah 2: bobot 5 (C4) di-apply 00:43:57 WIB:

```text
Sampel 539, gagal 32, jeda terpanjang 8.5 dtk, versi {'8.1.0': 474, '8.2.0': 33}, alih pada detik 4.1
curl 100×: 96 × 8.1.0, 3 × 8.2.0
CloudWatch target group canary: RequestCount 36, HTTPCode_Target_5XX 0, HTTPCode_ELB_5XX 0, p95 0,0025 dtk
```

Canary 6,5% dari 507 jawaban (simpangan baku binomial ±1 poin persen untuk p = 0,05). Kegagalan probe bukan dari canary: 5xx di target group canary 0, dan laju gagal yang sama (±5%) sudah muncul saat bobot 0. Keputusan: promosi, dengan catatan jumlah permintaan canary (36) di bawah kriteria produksi 200 pada K-08-002. Promosi dua langkah: bobot 0 di-apply, lalu `versi_stabil = "8.2.0"` dan canary dihapus; rollout ECS selesai dalam ±2 menit (loop curl 18 × 8.2.0).

## Catatan Bagian E — Bangun Ulang dari Nol

Bongkar penutup kelas (00:02:30–00:06:42 WIB, 23-11): `33 destroyed` dalam 4 menit 12 detik; layanan ECS paling lama (3 menit 20 detik), lalu ALB (19 detik). Bangun ulang (Tugas butir 2) dengan `versi_stabil = "8.1.0"`: plan `33 to add`, apply selesai sebelum 00:14:57, ALB baru `koma-123450039-m08-457817837.ap-southeast-2.elb.amazonaws.com`, `SEHAT setelah 0.6 detik`, `date` 00:15:54. Total dari awal bongkar sampai sehat 13 menit 24 detik, dan dari selesai bongkar sampai sehat paling lama 9 menit 12 detik (termasuk jeda commit K-08; jam mulai apply tidak tercatat). Pesanan sesudah bangun ulang: `P-5577dedc88aa`, `P-2311cedab8f3` (8.1.0).

Yang tidak ikut dibangun ulang (Tabel 8.5): registri dan image 8.0.0/8.1.0, stack `m00-*` (role pipeline, OIDC, verifier, budget), dan bucket state (`m08/layanan.tfstate` dikosongkan lalu diisi ulang). Yang hilang: isi arsip lama (`P-424b4a1b5c74` dan dua lainnya) dan log fungsi pengarsip, karena bucket dan log group bagian dari stack layanan (`force_destroy`). Nama DNS ALB juga berubah.

Potret aktif terakhir (Tugas butir 4), 01:31:35 WIB, lebih dari 15 menit sejak run image 8.2.0 (00:17):

```text
202  P-2fee8c917a67  8.2.0
202  P-21146fad1d5d  8.2.0
202  P-d0ca436e4dfa  8.2.0
```

`koma cek m08`: verifier 403.

## Catatan Bagian F — Penutup

Bongkar akhir Tugas: `33 destroyed`, selesai 01:35:49 WIB. Setelah bongkar kelas, `koma sisa` menampilkan registri `koma-123450039-m08-api` dan bucket state fondasi; entri ECS dan aturan security group yang masih tampil adalah sisa indeks tag (dicek: cluster `INACTIVE`, `InvalidSecurityGroupRuleId.NotFound`). Registri dibongkar setelah Tugas diunggah. `koma cek m08`: verifier 403.

## Langkah dan bukti

| Waktu (WIB) | Perintah atau run | Hasil singkat |
|---|---|---|
| 22-11 22:02 | run image 45036091216 | 8.0.0 terdorong setelah izin pipeline dan registri di-apply |
| 22-11 ±22:37 | `tofu apply` m08-layanan | 31 added |
| 22-11 22:48 | `koma pesan --jumlah 3` | 3 × 202, objek arsip dalam 1–2 detik |
| 22-11 22:57–23:03 | `koma beban /hitung` | CPU 86–87%, desired 1 → 2 pada 23:03:09 |
| 22-11 23:20 | run image 45043331445 | 8.1.0 terdorong (rerun setelah 429) |
| 22-11 23:29 | canary 20% | 26 jawaban 8.1.0, 5 gagal sebelum canary sehat |
| 22-11 23:34 | promosi satu langkah | 33 gagal, `ResourceInUse`; pulih lewat `modify-listener` |
| 22-11 | `tofu test` | 6 passed |
| 23-11 00:02–00:06 | `tofu apply bongkar.tfplan` | 33 destroyed |
| 23-11 ≤00:15 | bangun ulang 8.1.0 | 33 added, sehat 0,6 detik |
| 23-11 00:17 | PR #12, run image 45048570130 | 8.2.0 terdorong |
| 23-11 00:43:57 | canary 8.2.0 bobot 5 | 33/507 = 6,5%, 0 5xx, p95 2,5 ms |
| 23-11 ±01:28 | promosi dua langkah | stabil 8.2.0, 18/18 jawaban 8.2.0 |
| 23-11 01:31:35 | `koma pesan --jumlah 3` | 3 × 202 oleh 8.2.0 |
| 23-11 ±01:32–01:35:49 | bongkar | 33 destroyed |

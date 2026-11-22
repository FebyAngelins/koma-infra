# Latihan 7.1 — Satu kode, dua lingkungan, satu pesan beracun

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m07.json` (setelah Bagian G, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 07**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier, isi state, atau 12 digit ID akun (tulis `<akun>`).

## 1. Dua plan, satu kode (B.2)

| Hal | dev | prod | Baris di `env/*.tfvars` penyebabnya |
|---|---|---|---|
| Resource yang dibuat (baris `Plan:`) | `13 to add` (sebelum budget), lalu `1 to add` budget | `14 to add` (sebelum budget), lalu `1 to add` budget | `dengan_dlq = false` / `true` (antrean `-gagal` dibuat dengan `count`) |
| Memori fungsi (MB) | 128 (log: `Memory Size: 128 MB`) | 256 (log: `Memory Size: 256 MB`) | `ukuran = "kecil"` / `"sedang"` |
| DLQ (`-gagal`) | tidak ada (`dlq_url = null`) | ada (`koma-123450039-m07-prod-gagal`) | `dengan_dlq` |
| Retensi arsip (hari) | 1 | 7 | `retensi_hari = 1` / `7` |
| `cost-center` | `CC-101` | `CC-201` | `cost_center` |
| `data-class` | `internal` | `rahasia` | `data_class` |
| Anggaran (USD) | 2.0 | 5.0 | `anggaran_usd = 2` / `5` |

Kedua state terpisah di bucket state: `m07/dev.tfstate` (25682 byte) dan `m07/prod.tfstate` (27655 byte), dipilih dengan `tofu init -reconfigure -backend-config=env/<lingkungan>.backend.hcl`.

Mengapa modul tidak memerlukan satu pun `if lingkungan == "prod"`: modul `antrean-arsip` hanya menerima nilai (`ukuran`, `retensi_hari`, `dengan_dlq`, `versi`) dan mengubahnya menjadi resource lewat pemetaan dan syarat pada nilai itu sendiri, misalnya `local.memori[var.ukuran]` untuk memori dan `count = var.dengan_dlq ? 1 : 0` untuk DLQ. Modul tidak perlu tahu nama lingkungannya untuk memutuskan bentuk resource; keputusan "prod butuh DLQ dan ukuran sedang" ada di `env/prod.tfvars`, dan ditegakkan di luar modul oleh `check "prod_tangguh"` dan aturan 3–4 Conftest. Dengan begitu lingkungan ketiga (staging di G2) cukup diberi satu berkas nilai baru tanpa menyentuh modul.

## 2. Satu pesan beracun, dua nasib (D.1, D.2)

Potongan log prod (baris `gagal` dengan `messageId` yang sama):

```text
2026-11-22T12:41:08.469000+00:00 … {"gagal": "eac1e250-a3d7-49c7-97d8-1fbf62d7141d", "alasan": "field hilang: id_pesanan"}
2026-11-22T12:41:38.465000+00:00 … {"gagal": "eac1e250-a3d7-49c7-97d8-1fbf62d7141d", "alasan": "field hilang: id_pesanan"}
2026-11-22T12:42:08.468000+00:00 … {"gagal": "eac1e250-a3d7-49c7-97d8-1fbf62d7141d", "alasan": "field hilang: id_pesanan"}
```

Potongan log dev:

```text
2026-11-22T13:29:35.289Z {"gagal": "d85a3e4b-f8d4-403a-9de8-8ff78814c039", "alasan": "field hilang: id_pesanan"}
2026-11-22T13:30:05.285Z {"gagal": "d85a3e4b-f8d4-403a-9de8-8ff78814c039", "alasan": "field hilang: id_pesanan"}
2026-11-22T13:30:35.294Z {"gagal": "d85a3e4b-f8d4-403a-9de8-8ff78814c039", "alasan": "field hilang: id_pesanan"}
```

| Hal | prod | dev |
|---|---|---|
| Jumlah percobaan yang terlihat | 3, lalu berhenti | terus berulang (masih berputar saat diperiksa pukul 20.29–20.30 WIB) |
| Jarak antarpercobaan (detik) | 30 (12:41:08 → 12:41:38 → 12:42:08 UTC) | 30 (13:29:35 → 13:30:05 → 13:30:35 UTC) |
| Tempat pesan berakhir | DLQ `koma-123450039-m07-prod-gagal`, `ApproximateNumberOfMessages = 1` | tetap di antrean dev (`ApproximateNumberOfMessagesNotVisible = 1`) sampai retensi 1 hari habis atau antrean dihapus |

Penjelasan dengan *visibility timeout*, `maxReceiveCount`, dan `batchItemFailures`: saat fungsi menerima pesan, SQS menyembunyikannya selama *visibility timeout* 30 detik. Pesan rusak tidak punya `id_pesanan`, jadi fungsi melaporkan `messageId`-nya di `batchItemFailures` dan tidak menghapusnya; setelah 30 detik pesan terlihat lagi dan diambil ulang, itulah jarak 30 detik di kedua log. Di prod, antrean punya `redrive_policy` dengan `maxReceiveCount = 3`, sehingga setelah diterima tiga kali SQS memindahkannya ke antrean `-gagal` dan percobaan berhenti. Di dev tidak ada `redrive_policy`, sehingga pesan berputar terus dan setiap putaran adalah satu pemanggilan fungsi yang dibayar.

Mengapa dua pesanan sah di batch yang sama hanya diarsipkan sekali, dan apa yang terjadi bila pesanan sah yang sama terkirim dua kali: fungsi memproses setiap pesan sendiri-sendiri dan hanya melaporkan pesan yang gagal di `batchItemFailures` (pemetaan memakai `ReportBatchItemFailures`), sehingga SQS menghapus dua pesanan sah (`P-20261122124105-001` dan `-002`, keduanya tercatat `{"arsip": …}` sekali) dan hanya mengembalikan pesan rusak. Tanpa itu, satu pesan rusak membuat seluruh batch diulang dan pesanan sah ikut diarsipkan berkali-kali. Bila pesanan sah yang sama terkirim dua kali (SQS standar menjamin at-least-once), fungsi menulis objek dengan nama yang ditentukan `id_pesanan`, yaitu `arsip/<tanggal>/P-….json`, sehingga pengiriman kedua menimpa objek yang sama dan tidak membuat arsip ganda; konsumennya idempoten.

## 3. Showback (C.2)

Keluaran `koma showback`:

```text
Showback NIM 123450039, modul m07 (Resource Groups Tagging API; role IAM tidak terbaca)
lingkungan cost-center  data-class  resource
dev        CC-101       internal    1 lambda/event-source-mapping, 1 lambda/function, 1 logs/log-group, 1 s3, 1 sns, 1 sqs
prod       CC-201       rahasia     1 lambda/event-source-mapping, 1 lambda/function, 1 logs/log-group, 1 s3, 1 sns, 2 sqs
Tak bertuan (tanpa cost-center): 0
```

Keluaran `koma showback semua` (bagian "Tak bertuan"):

```text
Tak bertuan (tanpa cost-center): 3
  arn:aws:kms:ap-southeast-2:<akun>:key/3f5c6c74-26b1-473f-aa50-60b3394f0011 (modul m05)
  arn:aws:kms:ap-southeast-2:<akun>:key/60f338fa-9c4b-413f-b8b9-1d24c9c7c484 (modul m05)
  arn:aws:s3:::koma-123450039-tfstate-<akun> (modul m00)
```

Apa saja yang tak bertuan, mengapa, dan pusat biaya G1 mana yang semestinya menanggungnya: tiga resource dibuat sebelum aturan label G4 ada. Dua kunci KMS berasal dari stack M05 yang sudah dibongkar tetapi masih dalam masa tunggu penghapusan KMS, sehingga tetap tercatat; kunci itu melindungi password database RME, jadi semestinya ditanggung CC-110 Layanan Klinis (RME), atau CC-900 bila dianggap layanan kunci bersama. Bucket state `koma-123450039-tfstate-<akun>` dipakai semua stack dan pipeline, sehingga semestinya ditanggung CC-900 Platform TI bersama. Role pipeline, provider OIDC, dan role fungsi juga milik platform dan pemilik jalur, tetapi tidak muncul karena IAM tidak dibaca Tagging API, sehingga showback dari inventaris tag tidak melihat semuanya. Ini relevan dengan G3: kenaikan tagihan 55% tanpa pemilik yang jelas terjadi justru karena resource seperti ini tidak punya `cost-center`.

## 4. Bukti

- Potret 2 (B.3) pada 22-11 19.31 WIB, `Latihan lulus`: verifier menolak (403) di setiap `koma cek m07`, sehingga potret dilewati sesuai arahan dosen.
- Potret 3 (D.3) pada 22-11 ±19.45 WIB, `dlq_menangkap`: verifier menolak (403); bukti tidak langsung `ApproximateNumberOfMessages = 1` pada antrean `-gagal` prod.
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m07.json` yang diunggah: tidak tersedia, karena verifier menolak (403) sehingga bukti bertanda tangan tidak terbentuk.

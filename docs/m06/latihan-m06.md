# Latihan 6.1 — Satu alamat, dua versi, satu alarm

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m06.json` (setelah Bagian G, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 06**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier, isi state, atau 12 digit ID akun (tulis `<akun>`); nama DNS ALB dan ID resource boleh ditulis.

## 1. Impor tanpa mengganti (B.4)

Baris `Plan:` plan impor:

```text
Plan: 3 to import, 0 to add, 3 to change, 0 to destroy.
```

Perubahan in-place yang diusulkan (resource dan tag):

| Resource | Tag yang ditambah | Tag yang dihapus |
|---|---|---|
| `aws_instance.legacy[0]` | `stack`, `managed-by` | — |
| `aws_security_group.legacy[0]` | `stack`, `managed-by` | — |
| `aws_vpc_security_group_ingress_rule.legacy_http[0]` | `kursus`, `nim`, `kelompok`, `modul`, `stack`, `managed-by` | — |

Mengapa tidak ada `to add` maupun `to destroy`: tiga blok import mengisi state dengan ID yang sudah hidup (`i-0dc7c89eebf627ea2`, `sg-030b76f1f94f7d428`, `sgr-09f741338bd01b56a`), sehingga OpenTofu tidak menganggapnya resource baru. Atribut yang tidak dapat diubah di tempat (nama dan deskripsi SG, VPC, sumber dan port aturan, tipe server) saya tulis sama persis dengan hasil `koma legacy buat`, dan yang memang berbeda dari kode (AMI dan user data) ada di `ignore_changes`. Sisanya hanya tag dari `default_tags` provider yang tidak dipasang kontraktor; tag bisa diubah di tempat tanpa menyentuh server. Aturan masuk tidak punya tag sama sekali saat dibuat, karena itu ia mendapat enam tag sekaligus. Satu-satunya hambatan sebelum plan bersih adalah `cidr_saya` yang masih `GANTI/32`, yang ditolak validasi variabel sebelum plan berjalan.

Satu atribut yang, bila ditulis berbeda di kode, mengubah impor menjadi penggantian, dan akibatnya bagi pengguna L2 kasus saya: `description` security group. AWS tidak menyediakan cara mengubah deskripsi SG, jadi satu huruf yang berbeda, misalnya `dibuat manual` ditulis `dibuat-manual`, membuat OpenTofu menghapus SG legacy dan membuat yang baru, dan server yang memakainya ikut terganggu karena SG-nya harus dilepas. Bagi KSL, Sistem Antrean Pendaftaran v0.9 (L1) dipakai 140 kios yang alamatnya tertanam di firmware dan butuh sekitar 3 bulan untuk diperbarui (L2), serta 380 petugas. Kios menampilkan galat setelah 3 detik (L4), jadi penggantian yang tidak sengaja langsung terlihat sebagai antrean pendaftaran yang berhenti di semua klinik, padahal tujuan babak ini justru tanpa jeda yang terasa.

Risiko `ignore_changes = [ami, user_data, user_data_base64]` bagi kode sebagai sumber kebenaran: untuk tiga atribut itu kode berhenti mengawasi kenyataan. Kalau seseorang mengganti AMI atau skrip boot legacy, plan tetap `No changes`, sehingga kode tidak lagi menggambarkan apa yang sebenarnya dijalankan server. Untuk legacy yang akan dibongkar di Bagian F ini masih dapat diterima, karena tujuannya hanya mengambil alih pengelolaan tanpa mengganti server. Saya mengalami sisi lainnya di server hijau: data AMI `most_recent` bergeser antar plan sehingga plan alih sempat menjadi `2 to add, 1 to change, 2 to destroy`, lalu saya menambah `ignore_changes = [ami]` di server hijau. Daftar seperti ini harus tetap pendek dan beralasan, karena setiap atribut yang diabaikan adalah tempat drift yang tidak akan pernah terlihat.

## 2. Alih tanpa jeda yang terasa (C.8)

Baris `Plan:` plan alih dan resource yang berubah:

```text
  # aws_lb_listener.http will be updated in-place
      ~ default_action {
          ~ target_group_arn = "…targetgroup/koma-123450039-m06-biru/312890af4d75cfba" -> "…targetgroup/koma-123450039-m06-hijau/ff332635a6646ed0"
        }
Plan: 0 to add, 1 to change, 0 to destroy.
```

Ringkasan `koma probe`:

| Sampel | Gagal | Jeda terpanjang (dtk) | Versi yang terlihat | Alih pada detik |
|---|---|---|---|---|
| 235 | 0 | 0.0 | `0.9.0`: 158, `6.0.0`: 77 | 80.8 |

Mengapa listener ALB menghasilkan jeda sekecil ini (dan apa batas resolusi probe): ALB memilih target group untuk setiap permintaan. Mengubah listener tidak mematikan server mana pun; legacy tetap hidup dan sehat di target group biru, dan server hijau sudah dinyatakan sehat oleh ALB sebelum menerima lalu lintas, sehingga permintaan berikutnya langsung dijawab hijau. Hasil `0 gagal` berarti tidak ada jeda yang lebih panjang dari selang probe 0,5 detik; jeda yang lebih pendek dari itu tidak terlihat oleh probe ini. Syarat "hijau sudah sehat" itu terbukti pada percobaan pertama saya pukul 10.57 WIB, yang gagal: target group hijau berstatus `unused` karena belum dirujuk listener, sehingga ALB belum pernah menguji servernya, dan ternyata layanan `koma-api` di server hijau tidak berjalan. Probe mencatat `Sampel 236, gagal 87, jeda terpanjang 45.0 dtk, versi {'0.9.0': 149}, alih pada detik None` dan ALB menjawab 502, lalu saya rollback ke biru. Setelah unit diperbaiki dan aturan listener `X-Koma-Uji: hijau` membuat ALB menguji hijau lebih dulu (target `healthy`, `curl` dengan header menjawab `6.0.0`), alih kedua pukul sekitar 11.27–11.28 WIB berjalan tanpa gagal.

Perbandingan dengan ambang L4 dan jadwal L3 kasus saya: L4 mengizinkan jeda paling lama 2 detik karena kios menampilkan galat setelah 3 detik, dan probe tidak mencatat jeda yang melewati 0,5 detik, jadi alih kedua memenuhi L4. Percobaan pertama dengan jeda 45 detik jauh melampauinya dan bagi KSL setara insiden. Karena risiko terbesarnya ternyata bukan jeda tetapi versi baru yang tidak siap, peralihan produksi tetap dijadwalkan di jendela pemeliharaan Selasa 01.00–04.00 (L4), di dalam jam sepi 00.00–05.00 (L3), dengan rollback `aktif = "biru"` yang sudah terlatih sebagai jalan kembali.

## 3. Alarm yang terbukti (D.5)

Ringkasan `koma beban`:

```text
Permintaan 943, gagal 0, p50 740 ms, p95 830 ms
```

Riwayat alarm (`describe-alarm-history`, `StateUpdate`):

```text
2026-11-20T20:01:41.253000+07:00        Alarm updated from ALARM to OK
2026-11-20T19:52:41.253000+07:00        Alarm updated from OK to ALARM
2026-11-20T19:43:41.253000+07:00        Alarm updated from ALARM to OK
2026-11-20T19:34:41.253000+07:00        Alarm updated from OK to ALARM
2026-11-20T19:30:41.253000+07:00        Alarm updated from INSUFFICIENT_DATA to OK
```

Beban dijalankan dua kali (terlihat dari `RequestCount` per menit: 158, 313, 312, 151 pada 19.31–19.34, lalu lagi mulai 19.49), dan keduanya menyalakan alarm. Ringkasan di atas dari beban kedua.

| Hal | Waktu (WIB) |
|---|---|
| Beban dimulai | sekitar 19.49 (beban pertama sekitar 19.30.30) |
| Alarm `OK → ALARM` | 19.52.41 (beban pertama 19.34.41) |
| Beban berhenti | sekitar 19.52 (beban pertama sekitar 19.33.30) |
| Alarm `ALARM → OK` | 20.01.41 (beban pertama 19.43.41) |
| **Waktu deteksi** (menit) | sekitar 4 (3,7 dan 4,2 menit) |

Perbandingan dengan O5 dan anggaran galat O1 kasus saya (anggaran per 30 hari, persentase yang habis selama waktu deteksi): SLA 99,95% (E4, O1) memberi anggaran (1 − 0,9995) × 43.200 menit = 21,6 menit per 30 hari. Waktu deteksi sekitar 4 menit memakai 4 / 21,6 ≈ 19% anggaran sebelum ada yang tahu, sedangkan insiden O5 yang baru diketahui setelah 25 menit memakai 25 / 21,6 ≈ 116%, artinya anggaran bulan itu sudah habis sebelum ada yang bertindak. p95 di CloudWatch sekitar 0,51 detik selama beban, sedangkan p95 dari laptop 830 ms karena ikut menghitung perjalanan jaringan Indonesia–Sydney. Ambang lab 0,3 detik lebih rendah 0,2 detik daripada SLO KSL p95 < 500 ms (E5), jadi alarm ini lebih ketat dari SLO dan menyala sebelum SLO benar-benar dilanggar; kalau ambang disamakan dengan E5, beban 500 ms yang menghasilkan p95 sekitar 0,51 detik hanya tipis di atasnya. Waktu deteksi ini juga batas bawah: tanpa notifikasi SNS ke pemegang on-call (O6), alarm yang menyala belum memberi tahu siapa pun. Pemulihan ke `OK` butuh sekitar 9–10 menit setelah beban berhenti, lebih lama dari perkiraan naskah.

## 4. Bukti

- Potret 5 (D.6) pada (WIB), `Latihan lulus`: verifier menolak (403) di sepanjang modul, sehingga potret dilewati sesuai arahan dosen.
- Potret bersih (G.2) pada (WIB), `bersih_akhir`:
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m06.json` yang diunggah:

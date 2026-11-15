# Jawaban Analisis — Modul 04 (draf)

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 04** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m04/catatan-bukti.md`, `latihan-m04.md`, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (S1–S8, E4, A1, A4, A5) saat memakai angkanya, dan rujuk baris `K-04-*` bila relevan.

## Pertanyaan 1 — Block, file, atau object untuk data kasus

| Data kasus | Fakta kasus (angka) | Model akses | Layanan AWS dan batasnya | Dibangun di modul ini? |
|---|---|---|---|---|
| S1 | | | | |
| S2 | | | | |
| S4 | | | | |

Alasan dari letak file system dan pola akses (Surianarayanan & Chelliah, 2023, hlm. 164–166; Kumar & Singh, 2025, hlm. 38 dan 256–261), dengan bukti dari Bagian B dan C:

Untuk satu data: apa yang berubah bagi aplikasi dan tim (S7) bila dipindah sesuai S8:

## Pertanyaan 2 — State sebagai data sensitif dan penguncian

Apa yang dicegah `.tflock` dan buktinya (pesan, objek di bucket):

Apa yang tidak dicegah kunci (plan `-var="versi=4.0.0"` dari klon; Morris, 2025, hlm. 354):

Isi state stack saya dan siapa yang dapat membacanya (Gambar 4.5, Tabel 4.7); mengapa verifier cukup `s3:List*`:

Kaitan dengan A1, A4, A5 kasus: yang tidak boleh masuk state, siapa yang boleh membaca bucket state (Hafner, 2025, hlm. 153, 171, 177, 196); syarat dan risiko `force-unlock`:

## Pertanyaan 3 — Data hidup lebih lama daripada server, RPO, dan RTO

| Hal | Angka saya |
|---|---|
| Plan Bagian D (ringkasan; apakah volume muncul?) | |
| Penanda sebelum (B.5) | |
| Penanda sesudah (D.3) | |
| RTO penggantian (D.2–D.3) | |
| Target E4 kasus dan anggaran per 30 hari | |
| RPO dan RTO S1 dengan cara backup S5 hari ini | |

Yang diganti, yang tetap, dan buktinya; *segregate data infrastructure* (Morris, 2025, hlm. 382–384) dan batas EBS (Kumar & Singh, 2025, hlm. 256–257):

Porsi anggaran E4 per penggantian; apa yang tidak dilindungi volume terpisah dan apa yang dibutuhkan untuk mencapai target kasus (Kumar & Singh, 2025, hlm. 23–24); akibat bila S1 di root disk:

## Pertanyaan 4 — Versioning, lifecycle, biaya, dan retensi

Tiga aturan lifecycle saya dan apa yang dilakukan masing-masing (C.5.2, D.3.2; objek < 128 KB):

| Hitungan biaya S4 kasus | Nilai |
|---|---|
| Ukuran data terkini (S4) | |
| Asumsi laju penimpaan per bulan (tulis sendiri) | |
| `retensi_versi_hari` di `kasus.tfvars` | |
| Perkiraan ruang versi noncurrent | |
| Perkiraan biaya per bulan (Standard ±USD 0,025/GB, IA ±USD 0,0138/GB) | |

Mempertahankan `retensi_versi_hari` terhadap S4, S5, S6, S8: risiko 1 hari, biaya tanpa batas, versioning bukan backup (Gopalan, 2023, hlm. 92 dan 94; Hafner, 2025, hlm. 170–171); perlukah Object Lock:

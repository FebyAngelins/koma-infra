# Jawaban Analisis — Modul 03 (draf)

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 03** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m03/catatan-bukti.md`, `latihan-m03.md`, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (E1, E2, E3, E4, E5, E6, E7, E8, A1, A3, C3) saat memakai angkanya, dan rujuk baris `K-03-*` bila relevan.

## Pertanyaan 1 — Segmentasi tier, least privilege, dan zero trust

Matriks saya (dari B.3.2 dan potret verifier):

| Aturan (resource) | Asal | Tujuan (tier) | Port | Mengapa dibutuhkan |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |
| | | | | |
| | | | | |

Bila server web kasus saya disusupi, apa yang masih dapat dan tidak dapat dilakukannya (ke db, ke server web lain, ke internet); bukti dari Latihan 3.1:

Kaitan dengan E3, E7, dan A3 kasus; batas segmentasi jaringan menurut zero trust (Raje, 2021, hlm. 11 dan 143–144):

Komponen E1 yang belum punya tempat dan aturan yang dibutuhkannya:

## Pertanyaan 2 — Subnet privat tanpa NAT dan harganya

Bukti bahwa subnet privat tidak punya jalan keluar (A.6.2, C.4.3):

Yang dikorbankan bagi kasus saya (tambalan, unduhan paket, panggilan ke luar dari komponen E1):

| Jalan keluar | Biaya | Seberapa luas jalan yang dibuka | Beban tim (E6) | Cocok untuk kasus saya? |
|---|---|---|---|---|
| NAT gateway | | | | |
| VPC endpoint | | | | |
| Image dipanggang (Modul 02) | | | | |

Pilihan saya dan yang dikorbankan (Kumar & Singh, 2025, hlm. 238–239 dan 242; Morris, 2025, hlm. 198 dan 203):

## Pertanyaan 3 — ALB L7 dan health check terhadap SLA dan latensi

| Hal | Angka saya |
|---|---|
| Waktu ALB dibuat (C.4.1) | |
| `koma sehat` sampai SEHAT (C.4.2, D.2.2) | |
| Jendela deteksi health check (interval × ambang) | |
| Target E4 kasus dan anggaran per 30 hari | |
| `jumlah_web` kelompok | |
| Target p95 E5 kasus | |

Akibat satu server web mati terhadap anggaran E4; hop tambahan ALB dan jarak ke Sydney terhadap E5:

Yang diberikan L7 dibanding L4 bagi kasus saya; komponen yang tetap menjadi titik gagal tunggal (Gorton, 2022, hlm. 107–109; Kumar & Singh, 2025, hlm. 130–131 dan 248–249):

## Pertanyaan 4 — Dua stack dan kontrak output sebagai batas perubahan

Bukti Bagian D (yang tetap dan yang berganti; plan jaringan saat app dibongkar):

Empat output sebagai kontrak Stack State Lookup, risikonya, dan perbandingan dengan Resource Matching (Morris, 2025, hlm. 75–77 dan 163–168; Hafner, 2025, hlm. 196–200):

Untuk kasus saya (E6, E8): di stack mana titik masuk yang tidak boleh berubah alamatnya diletakkan, dan seberapa sering stack jaringan boleh berubah:

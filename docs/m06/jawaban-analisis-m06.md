# Jawaban Analisis — Modul 06 (draf)

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Draf ini ditulis sendiri, lalu disalin ke jendela **Soal analisis** pada **Tugas Individu — Modul 06** di Workbench. Bukti berasal dari pekerjaan Anda (`docs/m06/catatan-bukti.md`, `latihan-m06.md`, bukti verifier) dan berkas kasus kelompok. Sebut kode bukti kasus (L1–L5, E4, E5, E8, O1–O6) saat memakai faktanya, dan rujuk baris `K-06-*` bila relevan. Angka Sumatera Data di naskah adalah contoh, bukan angka kasus Anda.

## Pertanyaan 1 — Strategi dan bukti keberhasilan

Matriks Strategi saya (ringkas):

| Komponen | Strategi | Alasan (kode bukti) |
|---|---|---|
| Aplikasi legacy (L1) | | |
| Database (E8) | | |
| | | |

Mengapa strategi L1 berbeda dengan database, dan pada fase migrasi mana keputusan ini diambil ([S] hlm. 233–240):

Sinyal yang harus sudah terpantau sebelum "migrasi dan validasi" dinyatakan selesai, per lapisan ([S] hlm. 252–254; O1), dan yang tidak dapat saya pantau sebagai pengguna cloud:

## Pertanyaan 2 — Impor, kode, dan drift

Bukti saya (ringkasan plan impor, isi `ignore_changes`, exit code Bagian E):

Apa yang dibuktikan plan impor, dan apa yang tidak (Morris, 2025, hlm. 124):

Perubahan manual pada O5 kasus saya: tertangkap `-detailed-exitcode` atau tidak, dan mengapa (Morris, 2025, hlm. 201, 350–351; Hafner, 2025, hlm. 193–195):

## Pertanyaan 3 — Jeda, alarm, dan anggaran galat

| Ukuran | Hasil saya | Pembanding kasus (kode) |
|---|---|---|
| Jeda saat alih (probe) | | L4: |
| Jadwal peralihan produksi | — | L3: |
| Waktu deteksi alarm (menit) | | O5: |
| Anggaran galat per 30 hari | — | E4/O1: |
| Ambang alarm lab vs SLO latensi | 0,3 dtk, 1 × 60 dtk | E5: |

Analisis dan usulan perubahan (ambang, periode, alarm tambahan dari O4, penerima dari O6) beserta tawar-menawarnya (Domingus & Arundel, 2022, hlm. 303–305):

## Pertanyaan 4 — Kapan contract

Syarat sebelum contract dan apa yang hilang sesudahnya (Morris, 2025, hlm. 379–381):

Satu kriteria terukur dari observability yang saya bangun, untuk kasus saya (L2, L3, L5):

Utang keamanan legacy yang saya temukan dan pengaruhnya pada waktu contract:

# Latihan 3.1 — Membuktikan yang tertutup

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m03.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 03**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri.

## 1. Dua aturan yang sengaja salah

Salin isi `stacks/m03-app/latihan-salah.tf` yang Anda tulis, termasuk aturan kedua yang Anda susun dari Tabel 3.12a.

```hcl

```

Baris ringkasan `tofu plan` saat aturan ditambahkan, dan apakah ada server yang ikut diganti:

```text

```

## 2. Apa kata verifier

Salin baris `matriks_negatif` (dan `matriks_positif`) dari potret 3:

```text

```

Pembacaan saya, bagian demi bagian (jalur mana yang terbuka, aturan mana penyebabnya, prinsip mana yang dilanggar):

-
-
-

Mengapa `matriks_positif` tetap LULUS, dan mengapa `Latihan lulus` tetap `True`:

## 3. Uji dari laptop selagi aturan salah terpasang

| No. | Jalur | Perintah yang saya jalankan | Harapan | Hasil (salin baris keluaran) |
|---|---|---|---|---|
| 1 | laptop → ALB:80 | | BUKA | |
| 2 | laptop → web-1:80 langsung | | tidak sampai | |
| 3 | laptop → ALB:8080 | | tidak sampai | |
| 4 | jaringan lain → ALB:80 (opsional) | | tidak sampai | |

## 4. Mengapa tetap salah walaupun tidak ada paket yang lolos

Uji 2 gagal walaupun security group web menerima `0.0.0.0/0`. Lapis apa saja yang masih menutup jalan itu, dan perubahan apa di masa depan yang akan membuat aturan itu langsung berbahaya?

Untuk aturan db dari alb: apa yang kelak memakai security group alb, dan mengapa "db hanya dari web" lebih sempit daripada "db dari tier yang kita percaya"?

Kaitkan dengan ancaman A3 kasus kelompok Anda dan gagasan *defense in depth*:

## 5. Bukti

- Potret 3 (aturan salah terpasang) pada (WIB):
- Potret 4 (aturan salah dihapus) pada (WIB), `matriks_negatif`:
- `tofu plan` setelah berkas dihapus (`No changes`?):
- `stacks/m03-app/latihan-salah.tf` sudah tidak ada dan tidak ter-commit: ya / belum
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m03.json` setelah Bagian E:

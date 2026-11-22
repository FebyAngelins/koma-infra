# Latihan 8.1 — Skala, canary, dan satu pesanan yang terbukti

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m08.json` (setelah Bagian F, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 08**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier atau 12 digit ID akun (tulis `<akun>`); nama DNS ALB boleh ditulis.

## 1. Skala yang terbukti (C.2)

Ringkasan `koma beban`:

```text

```

| Menit sejak beban mulai | `desiredCount` stabil | `runningCount` stabil | Catatan (aktivitas skala) |
|---|---|---|---|
| 0 | | | |
| | | | |
| | | | |

Mengapa jumlah task tidak naik seketika, dan mengapa tidak langsung turun setelah beban berhenti:

Perbandingan dengan kebutuhan skala C3 dan batas C5 kasus saya:

## 2. Canary yang terukur (D.2)

Ringkasan `koma probe` dengan bobot canary 20:

| Sampel | Jawaban versi stabil | Jawaban versi canary | Persen canary |
|---|---|---|---|
| | | | |

Mengapa persentase yang terukur tidak tepat 20, dan berapa sampel yang dibutuhkan agar selisihnya kecil:

Metrik yang akan saya pakai untuk memutuskan promosi atau rollback (kaitkan dengan O1/E5 kasus saya):

## 3. Satu pesanan dari API ke arsip (B.6)

Keluaran `koma pesan` (satu baris):

```text

```

Kunci objek di bucket arsip dan baris log fungsi pengarsip untuk pesanan itu:

```text

```

Jalur pesanan dan identitas yang mengizinkan setiap langkahnya:

## 4. Bukti

- Potret 2 (C.2) pada (WIB), `skala_keluar`:
- Potret 3 (D.2) pada (WIB), `canary_berbobot`:
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m08.json` yang diunggah:

# Modul 06 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |
| Peninjau PR `m06` (NIM) | |
| Tautan *pull request* | |

Isi berkas ini sambil mengerjakan prosedur. Angka, ID, dan waktu disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Jangan menulis token verifier, isi state, atau 12 digit ID akun AWS (tulis `<akun>`); ID resource (`i-…`, `sg-…`) dan nama DNS ALB boleh ditulis. Berkas ini ikut di-commit dan masuk `koma-module-06.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `tofu apply` stack `m00-verifier` setelah `izin-m06.tf` (ringkasan) | |
| Impor yang diperlukan di `m00-verifier` (bila ada) | |
| `koma ip` saat `koma legacy buat` (bentuk `x.x.x.x/32`) | |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | |
| Ambang jeda dan jendela peralihan kasus (L4, L3) | |
| SLA/SLO kasus (E4, E5, O1) dan anggaran galat per 30 hari (hitungan) | |
| Lama insiden O5 kasus sampai ada yang tahu | |

## Catatan Bagian A — Inventarisasi

| Hal | Isi |
|---|---|
| ID server, SG, dan aturan legacy (`koma legacy info`) | |
| Atribut yang harus sama di kode (nama dan deskripsi SG, sumber dan deskripsi aturan, tipe, tag) | |
| Yang dapat diketahui dari AWS tentang server ini | |
| Yang tidak dapat diketahui dari AWS | |
| Temuan lain (IMDS, aturan keluar bawaan) | |

**Matriks Strategi** (kasus kelompok; satu baris per komponen)

| Komponen (kode bukti) | Strategi | Alasan |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

## Catatan Bagian B — Impor

| Hal | Isi |
|---|---|
| Ringkasan plan impor (`N to import, N to add, N to change, N to destroy`) | |
| Perubahan in-place yang diusulkan (resource dan tag) | |
| Atribut yang sempat membuat plan tidak bersih dan cara memperbaikinya | |
| Plan setelah apply dan `impor.tf` dihapus | |

## Catatan Bagian C — Expand dan alih versi

| Hal | Isi |
|---|---|
| Plan expand (ringkasan) | |
| `alb_url` | |
| `koma sehat` ke ALB (detik) dan `/versi` setelah expand | |
| Status target biru dan hijau | |
| Plan alih (resource yang berubah) | |
| Ringkasan `koma probe` saat alih biru → hijau (sampel, gagal, jeda terpanjang, versi, detik alih) | |
| Waktu alih (WIB) dan perbandingan dengan L4 | |
| Penanda konsol server hijau | |

## Catatan Bagian D — Observability

| Hal | Isi |
|---|---|
| Stream log dan contoh baris log dari CloudWatch Logs (tanpa data pribadi) | |
| Plan observability (ringkasan) | |
| Ringkasan `koma beban` (permintaan, gagal, p50, p95) | |
| Beban dimulai dan berhenti (WIB) | |
| Waktu alarm berubah ke `ALARM` dan kembali `OK` (dari riwayat alarm) | |
| Waktu deteksi (menit) dibandingkan O5 dan anggaran O1 | |

## Catatan Bagian E — Drift

| Hal | Isi |
|---|---|
| Garis dasar `tofu plan -detailed-exitcode` (exit code) | |
| Perintah yang menyuntikkan drift | |
| `tofu plan -detailed-exitcode` setelah drift: exit code dan ringkasan | |
| `tofu plan -refresh-only`: apa yang ditampilkan | |
| Keputusan (kode diubah atau kenyataan dikembalikan) dan alasannya | |
| Plan dan exit code setelah rekonsiliasi; ID server hijau sebelum dan sesudah | |

## Catatan Bagian F — Contract

| Hal | Isi |
|---|---|
| Pesan precondition dengan `-var aktif=biru` | |
| Plan contract (ringkasan dan resource yang dibongkar) | |
| Ringkasan `koma probe` selama contract | |
| Rollback yang dilatih sebelum contract (opsional: jeda kedua arah) | |
| Kriteria contract yang dipakai (kode bukti) | |

## Langkah dan bukti

Satu baris per `koma cek m06`. Potret aktif terakhir sebelum destroy di Tugas (setelah contract) harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal) |
|---|---|---|---|---|
| 1 | A.3 | legacy dibuat, belum diimpor | | |
| 2 | B.5 | legacy diimpor | | |
| 3 | C.7 | expand, listener ke biru | | |
| 4 | C.8 | alih, listener ke hijau | | |
| 5 | D.6 | alarm pernah menyala | | |
| 6 | E.2 | drift disuntikkan | | |
| 7 | E.4 | drift direkonsiliasi | | |
| 8 | G.2 | kosong (sesi kelas) | | |
| | Tugas | | | |
| | Tugas | | | |
| | Tugas | contract | | |
| | Tugas | kosong | | |

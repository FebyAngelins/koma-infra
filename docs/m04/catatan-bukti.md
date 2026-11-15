# Modul 04 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |
| Peninjau PR `m04` (NIM) | |

Isi berkas ini sambil mengerjakan prosedur. Angka, ID, dan waktu disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Jangan menulis token verifier, isi state, atau 12 digit ID akun AWS; tulis nama bucket sebagai `koma-<nim>-tfstate-<akun>`. Berkas ini ikut di-commit dan masuk `koma-module-04.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| Ringkasan plan `m00-verifier` setelah `izin-m04.tf` (P.2) | |
| `aws iam list-role-policies --role-name koma-verifier-ro` | |
| State `m00-verifier` ada di komputer ini, atau diimpor (sebutkan) | |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | |

## Langkah dan bukti

Satu baris per `koma cek m04`. Potret aktif terakhir sebelum destroy harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal) |
|---|---|---|---|---|
| 1 | B.6 | state di S3 + volume + db pertama | | |
| 2 | C.5.3 | + bucket arsip, laporan v1 | | |
| 3 | D.3.3 | volume sama + db baru, laporan v2 | | |
| 4 | E.2 | bersih (bucket state tetap) | | |
| 5 | Tugas Langkah 3 | nilai kasus, versi 4.2.0 | | |
| 6 | Tugas Langkah 4 | nilai kasus, versi 4.3.0 | | |
| 7 | Tugas Langkah 5 | bersih lagi | | |

## Catatan Bagian A

| Hal | Isi |
|---|---|
| Nama bucket state (dengan `<akun>`) | |
| Ringkasan plan dan apply `m00-state` | |
| Versioning, enkripsi, blok publik (A.3.1) | |
| Isi `stacks/m04-data/backend.hcl` (dengan `<akun>`) | |
| `terraform.tfstate` ada di `stacks/m00-state` dan tidak ter-commit (ya/tidak) | |

Mengapa state stack `m00-state` sendiri tidak disimpan di bucket yang dibuatnya (satu sampai dua kalimat):

## Catatan Bagian B

| Hal | Isi |
|---|---|
| `local.az` yang dipakai | |
| Ringkasan plan dan apply B.3 (state lokal) | |
| ID volume, ukuran, enkripsi, `DeleteOnTermination` (`describe-volumes`) | |
| ID server db pertama | |
| Jawaban `tofu init -migrate-state` dan hasilnya | |
| Versi `m04/data.tfstate` setelah migrasi (`list-object-versions`) | |
| `tofu state list` dan `tofu plan` setelah state lokal dihapus | |
| Baris `KOMA-PENANDA` (B.5) | |

Bukti bahwa state tidak lagi berada di folder `stacks/m04-data` (satu kalimat):

## Catatan Bagian C

| Hal | Isi |
|---|---|
| Nama bucket arsip (dengan `<akun>`) | |
| Ringkasan plan C.5.1 | |
| Tiga aturan lifecycle (C.5.2) | |
| Versi laporan setelah C.5 | |
| Jumlah versi state pada potret 2 | |

Mengapa aturan `laporan-dingin` tidak akan memindahkan objek laporan Anda:

## Catatan Bagian D

| Hal | Sebelum (B.5) | Sesudah (D.3) |
|---|---|---|
| ID server db | | |
| ID volume data | | |
| Baris `KOMA-PENANDA` | | |
| Versi laporan (jumlah) | | |

| Hal | Isi |
|---|---|
| Ringkasan plan D.1 (apakah `aws_ebs_volume.data` muncul?) | |
| Durasi `Destruction complete` attachment dan server, `Creation complete` server dan attachment | |
| Jam menjawab `yes` dan jam penanda server baru muncul | |
| RTO penggantian server db (menit:detik) | |
| `volume_selamat` dan `arsip_berversi` pada potret 3 | |

Apa yang diganti, apa yang tetap, dan apa arti `dibuat_oleh` serta `baris_riwayat`:

## Catatan Bagian E

| Hal | Isi |
|---|---|
| Ringkasan `tofu destroy` stack `m04-data` | |
| `tofu state list` sesudah destroy; apakah `m04/data.tfstate` masih ada di bucket | |
| `bersih_akhir` dan `Tugas lulus` pada potret 4 | |
| `koma sisa`: resource bertag, fondasi, instance tanpa `managed-by` | |

Mengapa bucket state tidak ikut dibongkar (satu sampai dua kalimat):

## Catatan Tugas

Pemetaan data kasus (rujuk Tabel S kasus kelompok):

| Data | Fakta kasus (angka) | Model akses | Layanan AWS | Dibangun di modul ini? | Alasan |
|---|---|---|---|---|---|
| S1 | | | | | |
| S2 | | | | | |
| S3 | | | | | |
| S4 | | | | | |
| S5 (apa yang dicakup versioning, apa yang tidak) | | | | | |

| Hal | Isi |
|---|---|
| `ukuran_data_gib` di `kasus.tfvars` dan hitungannya (1 GiB = 1 TB, ≤ ±70%; rujuk `K-04-…`) | |
| `retensi_versi_hari` di `kasus.tfvars` dan alasannya (rujuk `K-04-…`) | |
| Bila S1 > 2,8 TB: apa yang dibutuhkan sistem sesungguhnya | |
| Komputer tempat Tugas dikerjakan (sama dengan sesi kelas?) | |
| Ringkasan plan Langkah 3 (`size`, `noncurrent_days`) | |
| Penanda Langkah 3 dan Langkah 4 | |
| Hasil potret 5, 6, dan 7 | |
| Tautan *pull request* `modul-04` → `main` | |
| NIM peninjau dan tanggal persetujuan | |

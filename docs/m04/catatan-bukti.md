# Modul 04 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | k01 Klinik Sehat Lampung |
| Peninjau PR `m04` (NIM) | |

Isi berkas ini sambil mengerjakan prosedur. Angka, ID, dan waktu disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Jangan menulis token verifier, isi state, atau 12 digit ID akun AWS; tulis nama bucket sebagai `koma-<nim>-tfstate-<akun>`. Berkas ini ikut di-commit dan masuk `koma-module-04.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| Ringkasan plan `m00-verifier` setelah `izin-m04.tf` (P.2) | `izin-m04.tf` sudah ikut diterapkan bersama verifier di Modul 03 (apply `3 added`: role, `koma-baca-metadata`, `koma-baca-daftar-objek`), sehingga tidak ada penambahan di sesi ini |
| `aws iam list-role-policies --role-name koma-verifier-ro` | `["koma-baca-daftar-objek", "koma-baca-metadata"]` |
| State `m00-verifier` ada di komputer ini, atau diimpor (sebutkan) | ada di komputer ini (tidak diimpor) |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | laptop pribadi (macOS), 15 Nov 2026 |

## Langkah dan bukti

Satu baris per `koma cek m04`. Potret aktif terakhir sebelum destroy harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal) |
|---|---|---|---|---|
| 1 | B.6 | state di S3 + volume + db pertama | 15 Nov, sekitar 21.00 | tidak terambil: `koma cek m04` → `verifier menolak (403): Forbidden` (sama seperti M03; potret dilewati atas arahan dosen) |
| 2 | C.5.3 | + bucket arsip, laporan v1 | | |
| 3 | D.3.3 | volume sama + db baru, laporan v2 | | |
| 4 | E.2 | bersih (bucket state tetap) | | |
| 5 | Tugas Langkah 3 | nilai kasus, versi 4.2.0 | | |
| 6 | Tugas Langkah 4 | nilai kasus, versi 4.3.0 | | |
| 7 | Tugas Langkah 5 | bersih lagi | | |

## Catatan Bagian A

| Hal | Isi |
|---|---|
| Nama bucket state (dengan `<akun>`) | `koma-123450039-tfstate-<akun>` |
| Ringkasan plan dan apply `m00-state` | |
| Versioning, enkripsi, blok publik (A.3.1) | `Status: Enabled`; `SSEAlgorithm: AES256`; `BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, `RestrictPublicBuckets` semuanya `true`; `KeyCount` kosong (`null`, bucket belum berisi objek) |
| Isi `stacks/m04-data/backend.hcl` (dengan `<akun>`) | `bucket = "koma-123450039-tfstate-<akun>"`, `key = "m04/data.tfstate"`, `region = "ap-southeast-2"`, `encrypt = true`, `use_lockfile = true` |
| `terraform.tfstate` ada di `stacks/m00-state` dan tidak ter-commit (ya/tidak) | ya: berkas ada di folder, `git status` hanya menampilkan `.terraform.lock.hcl` |

Mengapa state stack `m00-state` sendiri tidak disimpan di bucket yang dibuatnya (satu sampai dua kalimat): bucket itu belum ada ketika stack ini pertama kali di-apply, sehingga state-nya tidak mungkin ditulis ke sana (masalah ayam dan telur); selain itu bila state-nya ikut tersimpan di bucket yang sama, kerusakan atau penghapusan bucket sekaligus menghilangkan catatan untuk membangunnya kembali.

## Catatan Bagian B

| Hal | Isi |
|---|---|
| `local.az` yang dipakai | `ap-southeast-2a` |
| Ringkasan plan dan apply B.3 (state lokal) | `Plan: 3 to add, 0 to change, 0 to destroy.`; `Apply complete! Resources: 3 added, 0 changed, 0 destroyed.` |
| ID volume, ukuran, enkripsi, `DeleteOnTermination` (`describe-volumes`) | `vol-0dc22177bf89c8b7f`, 1 GiB, `encrypted: true`, terpasang di `/dev/sdf` dengan `DeleteOnTermination: false` (root disk 8 GiB di `/dev/xvda` bernilai `true`; volume percobaan pertama `vol-0179cf3e7e3ecc40a` ikut di-destroy) |
| ID server db pertama | `i-0c929243b1f21ce62` (tanpa IP publik). Percobaan pertama `i-0f6c0b02e69e11c72` mendapat IP publik karena subnet bawaan `MapPublicIpOnLaunch=true` (sisa Modul 02); subnet bawaan diubah ke `false`, ketiga resource di-destroy dan dibangun ulang |
| Jawaban `tofu init -migrate-state` dan hasilnya | `yes` pada "Do you want to copy existing state to the new backend?"; `Successfully configured the backend "s3"!` (didahului `Releasing state lock`) |
| Versi `m04/data.tfstate` setelah migrasi (`list-object-versions`) | 1 versi: `m04/data.tfstate` IsLatest `True`, 10621 byte, 2026-11-15T13:53:51Z; tampak juga versi lama `m04/data.tfstate.tflock` (256 byte, IsLatest `False`), jejak kunci yang dipasang dan dilepas selama migrasi |
| `tofu state list` dan `tofu plan` setelah state lokal dihapus | `tofu state list` tetap menampilkan `aws_ebs_volume.data`, `aws_instance.db`, `aws_volume_attachment.data` dan tiga data source; `tofu plan`: `No changes. Your infrastructure matches the configuration.` lalu `Releasing state lock` |
| Baris `KOMA-PENANDA` (B.5) | `KOMA-PENANDA dibuat_oleh=i-0c929243b1f21ce62 waktu=2026-11-15T13:50:56Z sekarang=i-0c929243b1f21ce62 versi=4.0.0 baris_riwayat=1` |

Bukti bahwa state tidak lagi berada di folder `stacks/m04-data` (satu kalimat): setelah `terraform.tfstate` dan `terraform.tfstate.backup` dihapus dari folder, `tofu plan` tetap `No changes` dan memasang serta melepas kunci (`Releasing state lock`), artinya state dibaca dari `m04/data.tfstate` di bucket S3.

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

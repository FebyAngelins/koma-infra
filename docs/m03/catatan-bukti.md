# Modul 03 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Peninjau PR `m03` (NIM) | - (belum ada rekan peninjau) |

Isi berkas ini sambil mengerjakan prosedur. Angka, ID, dan alamat disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Jangan menulis nomor akun AWS, token verifier, atau ARN yang memuat nomor akun. Berkas ini ikut di-commit dan masuk `koma-module-03.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `role_arn` stack `m00-verifier` (ganti 12 digit akun dengan `<akun>`) | `arn:aws:iam::<akun>:role/koma-verifier-ro` |
| `koma info` menampilkan URL verifier (ya/belum) | |
| Kuota vCPU (`L-1216C47A`) | 16 |
| `jumlah_web` yang dipakai di kelas dan alasannya | 2: kuota 16 vCPU cukup untuk 3 × t3.micro (6 vCPU) |
| `cidr_saya` (keluaran `koma ip`) | |

## Langkah dan bukti

Satu baris per `koma cek m03`. Potret terakhir sebelum mengumpulkan harus potret bersih. Jangan menjalankan `koma cek m03` di antara destroy aplikasi dan destroy jaringan.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal) |
|---|---|---|---|---|
| 1 | C.5.2 | VPC + ALB pertama + server | | |
| 2 | D.3 | VPC sama + ALB baru | | |
| 3 | Latihan 3.1 butir 3 | dua aturan salah terpasang | | |
| 4 | Latihan 3.1 butir 5 | aturan salah dihapus | | |
| 5 | E.2 | bersih setelah destroy app dan network | | |
| 6 | Tugas Langkah 3 | nilai kasus (`cidr_vpc`, `jumlah_web`) | | |
| 7 | Tugas Langkah 4 | bersih lagi | | |

## Catatan Bagian A

| Hal | Isi |
|---|---|
| AZ yang dipakai (nama dan Zone ID) | |
| `cidrsubnet(var.cidr_vpc, 8, 0)` | |
| `cidrsubnet(var.cidr_vpc, 8, 11)` | |
| `cidrhost(cidrsubnet(var.cidr_vpc, 8, 10), 4)` dan mengapa bukan `.1` | |
| Ringkasan plan stack jaringan (`Plan: …`) | |
| `vpc_id` | |
| Subnet: nama, CIDR, AZ (empat baris) | |
| Rute di `rt-publik` (dari A.6.2) | |
| Rute di `rt-privat` (dari A.6.2) | |
| Plan kedua (A.6.3) | |

Mengapa subnet `privat-a` disebut privat walaupun ia berada di VPC yang sama dengan IGW (satu kalimat, rujuk Kumar & Singh, 2025, hlm. 232):

## Catatan Bagian B

Matriks konektivitas: isi kolom "Harapan pre-lab" sebelum sesi, kolom lain setelah B.3.2.

| Asal → tujuan:port | Harapan pre-lab | Aturan di kode (nama resource) | Tercatat di AWS (B.3.2) |
|---|---|---|---|
| laptop (`/32`) → alb:80 | | | |
| internet lain → alb:80 | | | |
| alb → web:80 | | | |
| alb → db:5432 | | | |
| web → db:5432 | | | |
| web → web:80 | | | |
| db → web:80 | | | |
| internet → web:80 / db:5432 | | | |

| Hal | Isi |
|---|---|
| Ringkasan plan stack aplikasi di B.3.1 | |
| ID security group alb, web, db | |
| Isi `keluar` security group db | |

Jalur mana yang dugaan pre-lab Anda berbeda dengan kode, dan mengapa:

## Catatan Bagian C

| Hal | Isi |
|---|---|
| Ringkasan plan C.4.1 | |
| `aws_lb.app` Creation complete (durasi) | |
| `url_lb` | |
| `ip_privat` (web-1, web-2, db) | |
| `koma sehat` ke ALB (detik) | |
| Nama host yang menjawab `/versi` (bergantian?) | |
| `curl --max-time 5` ke alamat privat web-1 | |
| Status target dari `describe-target-health` | |
| `laporan_klien` di bukti (kode dan isi) | |

## Catatan Bagian D

| Hal | Sebelum (potret 1) | Sesudah (potret 2) |
|---|---|---|
| `vpc_id` | | |
| `subnet_privat_ids` | | |
| `url_lb` (nama DNS ALB) | | |
| ID instance web-1 | | |
| `ip_privat` web-1 | | |

| Hal | Isi |
|---|---|
| `tofu plan` stack jaringan sebelum destroy app (D.1.1) | |
| Ringkasan `tofu destroy` stack app | |
| `koma sehat` alamat lama selama destroy | |
| `describe-vpcs` setelah destroy app | |
| Ringkasan `tofu apply` stack app lagi | |
| `siklus_terpisah` pada potret 2 | |

Apa yang tetap dan apa yang berganti; di mana titik masuk yang tidak boleh berubah alamatnya seharusnya diletakkan, dan stack mana yang memilikinya:

## Catatan Bagian E

| Hal | Isi |
|---|---|
| Ringkasan `tofu destroy` stack app | |
| Ringkasan `tofu destroy` stack jaringan | |
| `bersih_akhir` dan `Tugas lulus` pada potret 5 | |
| `koma sisa`: resource bertag, instance tanpa `managed-by`, fondasi | |

Mengapa stack aplikasi dibongkar lebih dulu (satu sampai dua kalimat):

## Catatan Tugas

Rencana alamat organisasi (tandai "asumsi" bila tidak tertulis di berkas kasus; rujuk E2, E7):

| Blok | Untuk (lokasi atau segmen) | Asumsi atau dari berkas kasus | Alasan ukuran |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| VPC anggota: | | | |

Pemetaan komponen E1:

| Komponen E1 | Tier (`alb`/`web`/`db`/belum dimodelkan) | Jalur yang dibutuhkan (asal → tujuan:port) | Perlu keluar internet? |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| | | | |

| Hal | Isi |
|---|---|
| `cidr_vpc` di `stacks/m03-network/kasus.tfvars` (rujuk `K-03-…`) | |
| `jumlah_web` di `stacks/m03-app/kasus.tfvars` (rujuk `K-03-…`) | |
| `tofu output` stack jaringan dengan nilai kasus | |
| `koma sehat` ke ALB kasus (detik) | |
| Jawaban `/versi` | |
| Hasil potret 6 dan potret 7 | |
| Tautan *pull request* `modul-03` → `main` | |
| NIM peninjau dan tanggal persetujuan | |

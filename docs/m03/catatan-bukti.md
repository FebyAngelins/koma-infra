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
| `role_arn` stack `m00-verifier` (ganti 12 digit akun dengan `<akun>`) | `arn:aws:iam::<akun>:role/koma-verifier-ro`; apply 10 Nov 2026 membuat 3 resource (role, `koma-baca-metadata`, dan `koma-baca-daftar-objek` dari `izin-m04.tf` yang ikut tersalin starter Modul 04) |
| `koma info` menampilkan URL verifier (ya/belum) | belum (nilai verifier dari dosen belum diterima) |
| Kuota vCPU (`L-1216C47A`) | 16 |
| `jumlah_web` yang dipakai di kelas dan alasannya | 2: kuota 16 vCPU cukup untuk 3 × t3.micro (6 vCPU) |
| `cidr_saya` (keluaran `koma ip`) | `103.126.172.221/32` (sesi 7 Nov 2026); `182.3.101.33/32` (sesi 10 Nov 2026) |

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
| AZ yang dipakai (nama dan Zone ID) | `ap-southeast-2a` (`apse2-az1`) dan `ap-southeast-2b` (`apse2-az3`); `ap-southeast-2c` (`apse2-az2`) tersedia tetapi tidak dipakai |
| `cidrsubnet(var.cidr_vpc, 8, 0)` | `10.30.0.0/24` (publik-a) |
| `cidrsubnet(var.cidr_vpc, 8, 11)` | `10.30.11.0/24` (privat-b) |
| `cidrhost(cidrsubnet(var.cidr_vpc, 8, 10), 4)` dan mengapa bukan `.1` | `10.30.10.4`; `.0` alamat jaringan, `.1` router VPC, `.2` resolver DNS Amazon, `.3` cadangan AWS, jadi host pertama yang dapat dipakai `.4` |
| Ringkasan plan stack jaringan (`Plan: …`) | `Plan: 13 to add, 0 to change, 0 to destroy.` (VPC, SG bawaan, IGW, 4 subnet, 2 route table, 4 asosiasi) |
| `vpc_id` | `vpc-091399dd3abd41d73` (sesi 7 Nov, lalu di-destroy); dibangun ulang 10 Nov 2026: `vpc-08b317e54e0af6fe8` (`cidr_vpc = 10.30.0.0/16`), apply `13 added` |
| Subnet: nama, CIDR, AZ (empat baris) | sesi 10 Nov: publik-a `subnet-015bdc4539df736f7`, publik-b `subnet-0f0f773773134ca74`, privat-a `subnet-0ff89cf97e6f33a99`, privat-b `subnet-0c4db0dad37c1248e` (CIDR dan AZ sama). Sesi 7 Nov: publik-a `subnet-0011d5b24fb2b3f7b` 10.30.0.0/24 ap-southeast-2a; publik-b `subnet-0c581836537f98318` 10.30.1.0/24 ap-southeast-2b; privat-a `subnet-08ec39adccae064d3` 10.30.10.0/24 ap-southeast-2a; privat-b `subnet-04a0543dd816c7036` 10.30.11.0/24 ap-southeast-2b |
| Rute di `rt-publik` (dari A.6.2) | `10.30.0.0/16 → local` dan `0.0.0.0/0 → igw-07a5615192db708f9`; subnet publik-a dan publik-b |
| Rute di `rt-privat` (dari A.6.2) | hanya `10.30.0.0/16 → local` (tanpa rute keluar, tanpa NAT); subnet privat-a dan privat-b |
| Plan kedua (A.6.3) | `No changes. Your infrastructure matches the configuration.` |

Mengapa subnet `privat-a` disebut privat walaupun ia berada di VPC yang sama dengan IGW (satu kalimat, rujuk Kumar & Singh, 2025, hlm. 232): karena route table-nya tidak punya rute `0.0.0.0/0` ke IGW, dan menurut Kumar & Singh (2025, hlm. 232) satu-satunya pembeda subnet publik dan privat adalah ada tidaknya rute langsung ke IGW, bukan nama subnet atau keberadaan IGW di VPC.

## Catatan Bagian B

Matriks konektivitas: isi kolom "Harapan pre-lab" sebelum sesi, kolom lain setelah B.3.2.

| Asal → tujuan:port | Harapan pre-lab | Aturan di kode (nama resource) | Tercatat di AWS (B.3.2) |
|---|---|---|---|
| laptop (`/32`) → alb:80 | buka | `alb_dari_saya` (cidr `103.126.172.221/32`) | alb masuk 80 dari `103.126.172.221/32` |
| internet lain → alb:80 | tutup | tidak ada aturan (hanya /32) | tidak ada CIDR lain di SG alb |
| alb → web:80 | buka | `alb_ke_web` (keluar) + `web_dari_alb` (masuk) | alb keluar 80 → `sg-09466fd15d74b1e3a`; web masuk 80 dari `sg-0e1d159735142c6b3` |
| alb → db:5432 | tutup | tidak ada aturan | db hanya menerima dari `sg-09466fd15d74b1e3a` (web) |
| web → db:5432 | buka | `web_ke_db` (keluar) + `db_dari_web` (masuk) | web keluar 5432 → `sg-0863ad2dd7623ac6d`; db masuk 5432 dari `sg-09466fd15d74b1e3a` |
| web → web:80 | tutup (dugaan awal: buka, karena satu subnet/segmen) | tidak ada aturan; SG web hanya menerima dari SG alb | sumber masuk web hanya `sg-0e1d159735142c6b3` |
| db → web:80 | tutup | tidak ada aturan; SG db tanpa aturan keluar | db `keluar: []` |
| internet → web:80 / db:5432 | tutup | tidak ada aturan; server tanpa IP publik, subnet privat tanpa rute keluar | tidak ada `0.0.0.0/0` di ketiga SG |

| Hal | Isi |
|---|---|
| Ringkasan plan stack aplikasi di B.3.1 | `Plan: 8 to add, 0 to change, 0 to destroy.` (3 SG + 5 aturan; dijalankan dengan `-target` agar server dan ALB belum ikut dibuat) |
| ID security group alb, web, db | sesi 10 Nov: alb `sg-0b4be40bfdb3d460b`, web `sg-03e6381c007584d55`, db `sg-0631aa532c30456ee` (sesi 7 Nov: alb `sg-0e1d159735142c6b3`, web `sg-09466fd15d74b1e3a`, db `sg-0863ad2dd7623ac6d`) |
| Isi `keluar` security group db | `[]` (kosong): db tidak dapat membuka koneksi ke mana pun |

Jalur mana yang dugaan pre-lab Anda berbeda dengan kode, dan mengapa: `web → web:80`. Saya semula mengira dua server web di tier yang sama otomatis bisa saling menjangkau seperti di jaringan flat (E7 KSL: satu segmen server). Di kode, SG web hanya menerima dari SG alb, jadi server web yang disusupi tidak dapat melompat ke saudaranya walaupun keduanya memakai SG yang sama.

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
| `10.0.0.0/16` | Pusat data primer dan kantor pusat Bandar Lampung (segmen server, kantor) | lokasi dari E2; blok adalah asumsi | /16 memberi ruang memecah segmen server yang kini flat (E7) menjadi tier tanpa ganti blok |
| `10.1.0.0/16` | Ruang server sekunder klinik utama Metro (replika DB, NAS kedua) | lokasi dari E2; blok adalah asumsi | sama besar dengan pusat agar replika dan DR dapat meniru tata letak pusat |
| `10.10.0.0/16` | 70 klinik, satu `/24` flat per klinik (`10.10.<n>.0/24`) | `/24` flat per klinik dari E7; blok induk asumsi | 256 slot `/24` untuk 70 klinik, sisa untuk klinik baru |
| `10.11.0.0/16` | 2 laboratorium rujukan dan 2 laboratorium mitra (VPN site-to-site) | lokasi dari E2, A4; blok asumsi | dipisah dari klinik agar aturan VPN mitra tidak menyentuh segmen klinik |
| `10.20.0.0/16` | VPN vendor kios antrean dan cadangan LTE | A4 (VPN permanen vendor); blok asumsi | dipisah agar vendor tidak lagi berada di segmen server pusat (A3, A4) |
| `10.40.0.0/14` | Seluruh VPC cloud (`10.40`–`10.43`), satu `/16` per anggota atau lingkungan | asumsi | menyisakan ruang untuk VPC tiap anggota kelompok dan lingkungan dev/staging/prod (G2) tanpa tumpang tindih kantor |
| VPC anggota: `10.41.0.0/16` | VPC Feby Angelina (123450039), anggota 1 k01; `10.40.0.0/16` dicadangkan untuk lingkungan bersama | asumsi | tidak memakai `10.30.0.0/16` kelas; tidak tumpang tindih blok kantor mana pun sehingga kelak bisa disambung VPN atau peering (E8) |

Pemetaan komponen E1:

| Komponen E1 | Tier (`alb`/`web`/`db`/belum dimodelkan) | Jalur yang dibutuhkan (asal → tujuan:port) | Perlu keluar internet? |
|---|---|---|---|
| Portal web pasien dan dasbor klinik | `alb` (pintu) + `web` | pasien/klinik → alb:80 (kelak 443); alb → web:80 | tidak |
| API RME (pendaftaran, rekam medis, order lab) | `web` (`koma_api.py` = web sekaligus API) | klinik, kios, lab mitra → alb:80; alb → web:80; web → db:5432 | tidak (mitra memanggil masuk lewat ALB) |
| Database relasional RME | `db` | web → db:5432 saja | tidak |
| Antrean dan worker (hasil lab, notifikasi, sinkronisasi klaim) | belum dimodelkan (kelak tier `worker` di subnet privat) | worker → db:5432; worker → gateway SMS/e-mail dan API 14 asuransi:443 | ya, terbatas ke tujuan tertentu (butuh NAT atau proxy keluar) |
| Analytics mutu layanan dan arsip | belum dimodelkan (E8: pindah ke cloud publik) | analytics → replika db:5432 (baca); ekspor agregat ter-pseudonim → object storage:443 | ya, hanya ke layanan penyimpanan (VPC endpoint cukup) |
| Object storage hasil lab PDF, foto klinis, rujukan | belum dimodelkan (Modul 04) | web → object storage:443 | tidak bila lewat VPC gateway endpoint |
| Kios antrean vendor (A4, bukan komponen E1 tetapi pemakai API) | di luar VPC | kios → alb:80 saja; tidak ada jalur ke web atau db | tidak |

| Hal | Isi |
|---|---|
| `cidr_vpc` di `stacks/m03-network/kasus.tfvars` (rujuk `K-03-…`) | `10.41.0.0/16` (K-03-001) |
| `jumlah_web` di `stacks/m03-app/kasus.tfvars` (rujuk `K-03-…`) | `2` (K-03-002) |
| `tofu output` stack jaringan dengan nilai kasus | |
| `koma sehat` ke ALB kasus (detik) | |
| Jawaban `/versi` | |
| Hasil potret 6 dan potret 7 | |
| Tautan *pull request* `modul-03` → `main` | |
| NIM peninjau dan tanggal persetujuan | |

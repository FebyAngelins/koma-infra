# Modul 01 — Catatan Bukti

Isi berkas ini segera setelah setiap langkah penting, lalu commit bersama `bukti/bukti-m01.json`.
Waktu ditulis dalam WIB. ID instance disalin dari terminal (`i-0…`); jangan menulis nomor akun AWS.

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

## Log langkah

| Langkah | Waktu (WIB) | Perintah | Hasil singkat |
|---|---|---|---|
| A.1 Konsol | 06-11-2026 12:59 | (konsol EC2) | `coba-konsol` `i-0d98afe3fcbca3d86` running |
| A.2 CLI dua kali | 06-11-2026 13:00 | `aws ec2 run-instances …` | dua `coba-cli`: `i-0aaecc5d9b7721705`, `i-0aa4d93233d5e29e2` |
| A.3 Cek + bongkar | 06-11-2026 13:03 | `koma cek m01`, `aws ec2 terminate-instances …` | potret 1 kosong, semua cek GAGAL; tiga instance Bagian A di-terminate |
| B.1 Anggaran | 06-11-2026 13:08 | `tofu apply m00.tfplan` | budget `koma-123450039-anggaran` USD 50 dibuat |
| B.4 Apply pertama | 06-11-2026 13:14 | `tofu apply m01.tfplan` | `Plan: 1 to add`; `web` `i-018dae2133d210786`, IP privat 172.31.27.176, selesai dalam 18 detik. Ternyata mendapat IP publik 13.211.39.50 karena ketiga subnet bawaan `MapPublicIpOnLaunch = True`; subnet diubah ke `False` (`aws ec2 modify-subnet-attribute --no-map-public-ip-on-launch`), lalu 13:38 `tofu apply -replace=aws_instance.web` → `web` baru `i-05ccf295a0b123508`, IP privat 172.31.24.65 |
| B.5 Potret 2–3 | 06-11-2026 13:15 / 13:39 | `koma cek m01` | potret 2: `tanpa_ip_publik` GAGAL (IP publik); potret 3 setelah replace: semua cek Latihan LULUS, `Latihan lulus: True` |
| C.1 Plan kedua | 06-11-2026 13:43 | `tofu plan -detailed-exitcode` | `No changes`; `exit code = 0` (idempoten) |
| C.3 Refaktor | 06-11-2026 13:46 | `tofu apply m01.tfplan` | `aws_instance.web has moved to aws_instance.layanan["web"]` (ID `i-05ccf295a0b123508` tetap); `api` dibuat; `Plan: 1 to add, 0 to change, 0 to destroy` |
| C.4 Potret 4 | 06-11-2026 13:47 | `koma cek m01` | `dua_peran` dan `refaktor_tanpa_ganti` LULUS; tinggal `bersih_akhir` GAGAL |
| D.1 Destroy + apply | 06-11-2026 13:49–13:52 | `tofu destroy`, `tofu apply` | destroy pertama terputus `RequestExpired` (kredensial habis), diulang setelah login: `0 destroyed` karena instance sudah terhapus; apply ulang `Plan: 2 to add` |
| D.1 Potret 5 | 06-11-2026 13:52 | `koma cek m01` | `reproducible` LULUS; tinggal `bersih_akhir` GAGAL |
| Latihan L.4 | 06-11-2026 14:00 | `tofu apply`, `koma cek m01` | `api` `t3.micro` → `t3.small` in-place dalam 38 detik, ID tetap; plan sesudahnya `exit code = 0` |
| E.1 Destroy + potret 7 | 06-11-2026 14:05–14:16 | `tofu destroy`, `koma cek m01`, `koma sisa` | `Destroy complete! Resources: 2 destroyed`; potret 7 kosong, 13 cek LULUS, `Latihan lulus: True`, `Tugas lulus: True` |
| Tugas: katalog kasus | 06-11-2026 14:22 | `tofu apply`, `koma cek m01` | `Plan: 3 to add`; `portal` `i-08a49c05fc032899b`, `rme-api` `i-0c898a87503b21673` (t3.small), `notif-worker` `i-04ca85b74522200a4`; potret 8 aktif, 3 instance, peran `api`, `web`, `worker` |
| Tugas: destroy akhir | 06-11-2026 14:26 | `tofu destroy`, `koma cek m01` | 3 instance dihapus; potret 9 kosong, `Tugas lulus: True`; `koma sisa`: instance tanpa `managed-by` 0, sisa bertag hanya instance/volume yang baru di-terminate |

## Dugaan Pre-lab (Langkah 5)

Dugaan sebelum praktikum: berapa langkah, berapa lama, dan siapa yang mengerjakan bila saya
"meminta satu server" di pusat data kampus.

| No | Langkah | Dikerjakan oleh | Perkiraan waktu |
|---|---|---|---|
| 1 | Menulis permintaan (spesifikasi CPU, RAM, disk, OS, kegunaan) | Mahasiswa/dosen pemohon | 30 menit |
| 2 | Mengajukan surat atau tiket ke UPT TIK | Pemohon | 1 hari |
| 3 | Persetujuan kaprodi atau pimpinan unit | Kaprodi / pimpinan | 1–3 hari |
| 4 | Pengecekan kapasitas host, rak, dan kuota | Admin UPT TIK | 1–2 hari |
| 5 | Membuat VM di hypervisor (atau membeli server bila kapasitas habis) | Admin server | 1 hari (berminggu-minggu bila beli) |
| 6 | Memasang sistem operasi dan pembaruan | Admin server | 2–4 jam |
| 7 | Mengatur jaringan: IP, VLAN, firewall | Admin jaringan | 1 hari |
| 8 | Membuat akun dan memberi akses ke pemohon | Admin server | 1 jam |
| 9 | Serah terima dan uji akses | Admin dan pemohon | 1 jam |

Dugaan total: sekitar 9 langkah, melibatkan 3–4 pihak, dan memakan 1–2 minggu kerja bila
kapasitas tersedia (bisa lebih dari sebulan bila harus membeli perangkat). Sebagian besar waktu
habis untuk menunggu persetujuan dan antrean, bukan untuk pekerjaan teknisnya. Keputusan
teknis (ukuran, OS, jaringan) hanya tercatat di tiket dan ingatan admin.

## Catatan Bagian A

- Waktu konsol (klik pertama sampai `Running`): ± 8 menit; jumlah isian yang disentuh: ± 6 (Nama, AMI dicek, tipe instance, key pair, IP publik, grup keamanan)
- Waktu CLI (Enter sampai `running`): ID instance keluar dalam beberapa detik, status `running` sudah terlihat kurang dari 1 menit kemudian
- ID instance: `coba-konsol` `i-0d98afe3fcbca3d86`; dua `coba-cli` `i-0aaecc5d9b7721705` dan `i-0aa4d93233d5e29e2` (nama sama, ID berbeda: tag `Name` bukan pengenal unik)
- Keputusan yang tidak tercatat di mana pun selain ingatan dan riwayat terminal saya:
  - Region Asia Pacific (Sydney) `ap-southeast-2`, dipilih lewat pemilih region di konsol
  - AMI Amazon Linux 2023 kernel-6.18, x86_64 (bawaan konsol; ID AMI tidak ditulis di mana pun)
  - Tipe instance `t3.micro`
  - Tanpa key pair (tidak ada login SSH)
  - IP publik dinonaktifkan (bawaan konsol justru Aktifkan)
  - Grup keamanan `default` (bawaan konsol justru membuat `launch-wizard-1` dengan SSH dari 0.0.0.0/0)
  - Subnet "Tidak ada preferensi" di VPC bawaan
  - Disk root 8 GiB gp3, tidak dienkripsi (bawaan)
  - Tag hanya `Name`; tidak ada tag pemilik, modul, atau `managed-by`
  - Di CLI: perintah yang sama dijalankan dua kali menghasilkan dua server bernama sama
- Semua instance Bagian A sudah di-terminate (bukti: `describe-instances` kosong; `tanpa_instance_liar` lulus pada potret 2): ya

## Catatan Bagian D

- Plan kedua (C.1): exit code = 0 (`No changes. Your infrastructure matches the configuration.`)
- ID sebelum destroy: `web` `i-05ccf295a0b123508`, `api` `i-0d7d80cf929db24ee`
- ID sesudah apply ulang: `web` `i-09379a18a1728d275`, `api` `i-0241a7743e310aecd` (nama, tipe `t3.micro`, AMI `ami-062900c135ab91582`, dan tag sama; ID berbeda)
- Waktu destroy: 13:49–13:50 WIB (terputus sekali karena kredensial habis); waktu apply ulang: 13:52 WIB, kedua instance selesai dalam kurang dari 1 menit
- Potret yang meluluskan `reproducible`: potret 4 dan potret 5 (sebelumnya sudah lulus sekali di potret 2 dan 3 karena `web` diganti dengan `-replace`)

### Model layanan

| Komponen | IaaS / PaaS / SaaS / bukan model layanan | Alasan (lapisan yang saya sentuh dan yang tidak) |
|---|---|---|
| Instance EC2 | IaaS | Saya memilih AMI, tipe instance, disk, jaringan, dan tag; isi sistem operasi menjadi urusan saya. Host fisik, hypervisor, dan jaringan fisik diurus AWS. |
| AWS Budgets | SaaS (fitur layanan terkelola, bukan server) | Saya hanya mengatur batas USD 50 dan e-mail peringatan; tidak ada server, OS, atau runtime yang saya sentuh. |
| Repo GitHub | SaaS | Saya hanya memakai fitur repo, branch, dan pull request lewat web dan `git push`; server Git, penyimpanan, dan OS diurus GitHub. |
| Workbench (panel Tugas) | SaaS | Saya hanya memakai aplikasi web untuk membaca naskah dan mengunggah tugas; server dan platformnya dikelola kampus. |
| `koma cek` | Bukan model layanan cloud | Skrip Python yang berjalan di laptop saya sendiri; ia hanya klien yang memanggil API AWS dengan kredensial saya, seperti AWS CLI. |

### Karakteristik cloud yang dialami

| Karakteristik ([S] hlm. 40–45) | Dialami / dibatasi / tidak | Bukti hari ini (perintah, keluaran, atau angka) |
|---|---|---|
| On-demand provisioning | Dialami | `tofu apply` membuat `web` dalam 16–18 detik; `run-instances` mengembalikan ID dalam beberapa detik, tanpa menunggu siapa pun. |
| Self-service | Dialami | Instance dibuat lewat konsol, CLI, dan OpenTofu dengan identitas saya sendiri, tanpa tiket ke admin (bandingkan dugaan pre-lab 1–2 minggu). |
| Resource pooling, multi-tenancy | Dialami, tidak terlihat langsung | Saya tidak memilih host fisik; instance berjalan di host bersama penyewa lain di AZ ap-southeast-2a/2b/2c, dan akun lain tidak terlihat dari akun saya. |
| Rapid elasticity | Dialami, dibatasi | Dua instance dihapus lalu dibuat ulang dalam sekitar 3 menit (D.1), tetapi ukuran dibatasi `t3.micro`/`t3.small` dan kuota vCPU akun kecil. |
| Measured service | Dialami, dengan jeda | Anggaran `koma-123450039-anggaran` USD 50 dengan `include_credit = false` memantau pemakaian; angka Current di Budgets belum langsung berubah karena data biaya diperbarui beberapa kali sehari. |
| Broad network access | Dialami | Konsol dan API dipanggil dari laptop pribadi lewat internet (`aws`, `tofu`, `koma`); kredensial sementara bisa kedaluwarsa (`RequestExpired`) sehingga perlu login ulang. |

## Potret Tugas

- Katalog kasus (`default` di `variables.tf`): kunci `portal`, `rme-api`, `notif-worker`; peran `web`, `api`, `worker`; ukuran `kecil`, `sedang`, `kecil`
- Potret aktif katalog kasus: nomor 8, waktu 06-11-2026 14:22:01 WIB (`2026-11-06T07:22:01Z`)
- Potret bersih terakhir: nomor 9, waktu 06-11-2026 14:26:41 WIB (`2026-11-06T07:26:41Z`); `tugas_lulus`: true

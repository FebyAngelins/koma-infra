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
| A.3 Cek + bongkar | | `koma cek m01`, `aws ec2 terminate-instances …` | |
| B.1 Anggaran | | `tofu apply m00.tfplan` | |
| B.4 Apply pertama | | `tofu apply m01.tfplan` | |
| B.5 Potret 2 | | `koma cek m01` | |
| C.1 Plan kedua | | `tofu plan -detailed-exitcode` | |
| C.3 Refaktor | | `tofu apply m01.tfplan` | |
| C.4 Potret 3 | | `koma cek m01` | |
| D.1 Destroy + apply | | `tofu destroy`, `tofu apply` | |
| D.1 Potret 4 | | `koma cek m01` | |
| Latihan L.4 (potret 5) | | `tofu apply`, `koma cek m01` | |
| E.1 Destroy + potret 6 | | `tofu destroy`, `koma cek m01`, `koma sisa` | |
| Tugas: katalog kasus | | `tofu apply`, `koma cek m01` | |
| Tugas: destroy akhir | | `tofu destroy`, `koma cek m01` | |

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
- Semua instance Bagian A sudah di-terminate (bukti: `describe-instances` kosong; `tanpa_instance_liar` lulus pada potret …): ya / belum

## Catatan Bagian D

- Plan kedua (C.1): exit code = 
- ID sebelum destroy: `web` …, `api` …
- ID sesudah apply ulang: `web` …, `api` …
- Waktu destroy: … ; waktu apply ulang: …
- Potret yang meluluskan `reproducible`: potret … dan potret …

### Model layanan

| Komponen | IaaS / PaaS / SaaS / bukan model layanan | Alasan (lapisan yang saya sentuh dan yang tidak) |
|---|---|---|
| Instance EC2 | | |
| AWS Budgets | | |
| Repo GitHub | | |
| Workbench (panel Tugas) | | |
| `koma cek` | | |

### Karakteristik cloud yang dialami

| Karakteristik ([S] hlm. 40–45) | Dialami / dibatasi / tidak | Bukti hari ini (perintah, keluaran, atau angka) |
|---|---|---|
| On-demand provisioning | | |
| Self-service | | |
| Resource pooling, multi-tenancy | | |
| Rapid elasticity | | |
| Measured service | | |
| Broad network access | | |

## Potret Tugas

- Katalog kasus (`default` di `variables.tf`): kunci … peran … ukuran …
- Potret aktif katalog kasus: nomor …, waktu …
- Potret bersih terakhir: nomor …, waktu …; `tugas_lulus`: …

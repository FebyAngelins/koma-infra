# Modul 02 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |
| Peninjau PR `m02` (NIM) | - (belum ada rekan peninjau) |

Isi berkas ini sambil mengerjakan prosedur. Angka dan ID disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Berkas ini ikut di-commit dan masuk `koma-module-02.zip`.

## Dugaan pre-lab

| Dugaan | Isi |
|---|---|
| Waktu siap server goreng dibanding server dari AMI (detik) | sekitar 30–60 detik lebih lambat |
| Alasan dugaan | Server goreng harus menunggu cloud-init menulis aplikasi, berkas konfigurasi, dan unit, lalu menyalakan layanan; server dari AMI tinggal boot karena semua itu sudah terpanggang. |

## Langkah dan bukti

Satu baris per `koma cek m02`. Potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal) |
|---|---|---|---|---|
| 1 | C.4.5 | api 2.0.0 dari AMI 2.0.0 | 06-11-2026 14:52 | `Latihan lulus: True`, `Tugas lulus: False`; 11/13 LULUS, gagal `immutable` dan `bersih_akhir` |
| 2 | D.4 | api 2.1.0, ID baru | | |
| 3 | Latihan 2.1 | api 2.1.0 + server goreng | | |
| 4 | E.2.2 | bersih setelah `tofu destroy` | | |
| 5 | Tugas Langkah 2 | rilis kasus `<versi>` | | |
| 6 | Tugas Langkah 3 | bersih lagi | | |

## Catatan Bagian A

| Hal | Isi |
|---|---|
| AMI publik terbaru (ID dan nama) | Tiga AMI terbit bersamaan 2026-10-30: `ami-062900c135ab91582` (`al2023-ami-2023.12.20261102.0-kernel-6.18-x86_64`), `ami-099dee059bb2abc3c` (kernel-6.12), `ami-0fe72ee76eb56783b` (kernel-6.1). Data source `most_recent = true` memilih `ami-062900c135ab91582` (kernel-6.18), sama seperti di Modul 01. |
| `pemilik` (OwnerId) | `137112412989` (akun Amazon, bukan akun saya) |
| `virtualisasi`, `ena`, `root` | `hvm`, `true`, `ebs` (arsitektur `x86_64`, publik `true`) |
| Hypervisor, vCPU, memori `t2.micro` | `xen`, 1 vCPU, 1024 MiB, burstable |
| Hypervisor, vCPU, memori `t3.micro` | `nitro`, 2 vCPU, 1024 MiB, burstable |
| Hypervisor, vCPU, memori `t3.small` | `nitro`, 2 vCPU, 2048 MiB, burstable |
| Ukuran user data (`length(local.cloud_init)`) | 5558 karakter (sekitar sepertiga batas 16 KB berkat `base64gzip()`) |

Mengapa pembangun cukup memakai `t3.micro` (satu kalimat): pembangun hanya menjalankan cloud-init yang menulis tiga berkas dan menyalakan satu layanan, tanpa mengunduh paket atau melayani pengguna, sehingga 2 vCPU burstable dan 1 GiB memori sudah lebih dari cukup sebelum ia dipotret menjadi AMI.

## Catatan Bagian B

| Hal | Isi |
|---|---|
| `aws_instance.pembangun` Creation complete | |
| `time_sleep.tunggu_cloud_init` Creation complete | |
| `aws_ami_from_instance.api` Creation complete | |
| **Waktu panggang** (jumlah ketiganya) | |
| ID dan nama AMI 2.0.0 | `ami-04c8c952bb796d41d`, `koma-123450039-m02-api-2.0.0` |
| `OwnerId` AMI (sama dengan akun saya?) | |
| Baris `Cloud-init ... Up N seconds` dari log konsol (beserta jamnya) | |

Apakah jeda 120 detik cukup, dan apa buktinya:

## Catatan Bagian C

| Hal | Isi |
|---|---|
| `url_api` | `http://3.27.73.80` |
| ID instance api | `i-0b8eff1c29db0b71f` (instance pertama `i-06301b3ed407219ad` lahir tanpa IP publik, lalu diganti dengan `tofu apply -replace=aws_instance.api` setelah subnet bawaan dikembalikan ke `MapPublicIpOnLaunch = True`) |
| `aws_instance.api` Creation complete | |
| **Waktu siap** dari `koma sehat` (detik) | |
| Jawaban `/versi` (versi dan host) | |
| Aturan masuk security group | satu aturan: TCP 80 dari `103.211.143.235/32` ("HTTP dari IP praktikan") |
| Isi `keluar` (IpPermissionsEgress) security group | `[]` (kosong): aturan keluar bawaan dicabut provider, sehingga server tidak bisa mengunduh apa pun keluar |

## Catatan Bagian D

| Hal | Sebelum (2.0.0) | Sesudah (2.1.0) |
|---|---|---|
| ID instance api | `i-0b8eff1c29db0b71f` | |
| IP publik api | 3.27.73.80 | |
| ID AMI | `ami-04c8c952bb796d41d` (`koma-123450039-m02-api-2.0.0`) | |

Rantai penggantian 2.0.0 → 2.1.0 (dari `tofu plan`):

| Resource | Simbol aksi | Atribut pemicu (`# forces replacement`) | Resource hulu penyebab |
|---|---|---|---|
| `aws_instance.pembangun` | | | |
| `time_sleep.tunggu_cloud_init` | | | |
| `aws_ami_from_instance.api` | | | |
| `aws_instance.api` | | | |

Baris `Plan:` :

Resource yang dihapus pertama kali dan akibatnya bagi pengguna API:

| Hal | Isi |
|---|---|
| Jam mengetik `yes` (WIB) | |
| Jam `koma sehat` alamat baru SEHAT (WIB) | |
| **Jeda layanan** | |
| Waktu panggang versi 2.1.0 | |
| Waktu siap versi 2.1.0 (`koma sehat`, detik) | |
| `koma sehat` alamat lama selama apply | |

## Catatan Bagian E

| Hal | Isi |
|---|---|
| Ringkasan `tofu destroy` (jumlah resource) | |
| `describe-images --owners self` setelah destroy | |
| `koma sisa`: resource bertag, instance tanpa `managed-by`, snapshot sisa AMI | |
| `bersih_akhir` dan `Tugas lulus` pada potret 4 | |

## Catatan Tugas

| Hal | Isi |
|---|---|
| Versi rilis kasus dan alasannya (rujuk `K-02-*`) | |
| Ukuran server api (`t3.micro`/`t3.small`) dan alasannya | |
| ID AMI publik yang dipakai saat Tugas | |
| Waktu panggang | |
| Waktu siap (`koma sehat`, detik) | |
| ID instance api rilis kasus | |
| Jawaban `/versi` | |
| Tautan *pull request* `modul-02` → `main` | |
| NIM peninjau dan tanggal persetujuan | |

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
| 2 | D.4 | api 2.1.0, ID baru | 06-11-2026 15:06 | `immutable` LULUS; hanya `bersih_akhir` GAGAL; `Latihan lulus: True` |
| 3 | Latihan 2.1 | api 2.1.0 + server goreng | 06-11-2026 15:14 | 3 instance aktif (api, pembangun, goreng `http://15.135.214.5`); `Latihan lulus: True`, hanya `bersih_akhir` GAGAL |
| 4 | E.2.2 | bersih setelah `tofu destroy` | 06-11-2026 15:23 | potret kosong, 13/13 LULUS; `Latihan lulus: True`, `Tugas lulus: True` |
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
| ID instance api | `i-0b8eff1c29db0b71f` | `i-0b6c3a8069db8e0a0` |
| IP publik api | 3.27.73.80 | 15.135.90.129 |
| ID AMI | `ami-04c8c952bb796d41d` (`koma-123450039-m02-api-2.0.0`) | `ami-0808a03b2cea594d9` (`koma-123450039-m02-api-2.1.0`) |

Rantai penggantian 2.0.0 → 2.1.0 (dari `tofu plan`):

| Resource | Simbol aksi | Atribut pemicu (`# forces replacement`) | Resource hulu penyebab |
|---|---|---|---|
| `aws_instance.pembangun` | `-/+` | `user_data` (`KOMA_VERSI` dan `Description` berubah 2.0.0 → 2.1.0) | `var.versi` → `local.cloud_init`, ditambah `user_data_replace_on_change = true` |
| `time_sleep.tunggu_cloud_init` | `-/+` | `triggers` (`instance` → known after apply) | `aws_instance.pembangun` (ID baru) |
| `aws_ami_from_instance.api` | `-/+` | `name` (`…-api-2.0.0` → `…-api-2.1.0`) dan `source_instance_id` (known after apply) | `var.versi` dan `time_sleep.tunggu_cloud_init` |
| `aws_instance.api` | `-/+` | `ami` (`ami-04c8c952bb796d41d` → known after apply) | `aws_ami_from_instance.api` (AMI baru) |

Baris `Plan:` : `Plan: 4 to add, 0 to change, 4 to destroy.` (security group dan aturannya tidak berubah)

Resource yang dihapus pertama kali dan akibatnya bagi pengguna API: `aws_instance.api` (server 2.0.0) dihapus paling awal karena urutan bawaan "hapus dulu, lalu buat"; pengganti baru dibuat paling akhir setelah pembangun, jeda 120 detik, dan AMI baru selesai, sehingga pengguna API tidak terlayani selama seluruh proses panggang dan IP publiknya berganti.

| Hal | Isi |
|---|---|
| Jam mengetik `yes` (WIB) | 14:57 |
| Jam `koma sehat` alamat baru SEHAT (WIB) | sekitar 15:03 |
| **Jeda layanan** | sekitar 6 menit (14:57 → 15:03); selama itu tidak ada server api yang melayani, dan alamat lama 3.27.73.80 hilang permanen |
| Waktu panggang versi 2.1.0 | |
| Waktu siap versi 2.1.0 (`koma sehat`, detik) | |
| `koma sehat` alamat lama selama apply | |

## Catatan Bagian E

| Hal | Isi |
|---|---|
| Ringkasan `tofu destroy` (jumlah resource) | 6 resource (pembangun, jeda, AMI, security group, aturan masuk, api); percobaan pertama tidak jalan karena dua perintah tersalin menempel (`destroycd`) |
| `describe-images --owners self` setelah destroy | kosong; AMI `ami-0808a03b2cea594d9` sudah dideregistrasi |
| `koma sisa`: resource bertag, instance tanpa `managed-by`, snapshot sisa AMI | 25 resource bertag (instance dan volume yang baru di-terminate, hilang sendiri sekitar 1 jam); instance tanpa `managed-by`: 0; snapshot sisa AMI: 0 |
| `bersih_akhir` dan `Tugas lulus` pada potret 4 | `bersih_akhir` LULUS, `Tugas lulus: True` (potret 4, 2026-11-06T08:23:28Z) |

## Catatan Tugas

| Hal | Isi |
|---|---|
| Versi rilis kasus dan alasannya (rujuk `K-02-*`) | `2.2.0`: rilis fitur pertama untuk KSL yang kompatibel dengan 2.1.0, sehingga MINOR naik (K-02-001) |
| Ukuran server api (`t3.micro`/`t3.small`) dan alasannya | `t3.small`: E4 SLA 99,95% dan E5 p95 < 500 ms; latensi Lampung–Sydney sekitar 100–150 ms sudah memakan sebagian target, sehingga butuh memori dan kinerja dasar CPU dua kali t3.micro (K-02-002) |
| ID AMI publik yang dipakai saat Tugas | `ami-062900c135ab91582` (al2023 kernel-6.18, sama dengan di kelas) |
| Waktu panggang | tidak tercatat per resource (baris `Creation complete` tidak tersimpan); apply 6 resource selesai dalam beberapa menit, AMI hasilnya `ami-0801e67215d14e784` (`koma-123450039-m02-api-2.2.0`) |
| Waktu siap (`koma sehat`, detik) | 0,2 detik setelah perintah dijalankan; server api pengganti (`-replace`) sudah sehat sebelum `koma sehat` mulai, sehingga waktu siap nyata ≈ waktu `Creation complete` instance (di bawah satu menit) |
| ID instance api rilis kasus | `i-095b9b2e4bb71543e` (potret 5, `http://16.178.57.245`), lalu diganti `-replace` menjadi `i-074e8d41a227c0c52` (potret 6, `http://3.26.35.158`) untuk mengukur waktu siap |
| Jawaban `/versi` | `{"versi": "2.2.0", "peran": "api", "host": "ip-172-31-46-198.ap-southeast-2.compute.internal"}` |
| Tautan *pull request* `modul-02` → `main` | |
| NIM peninjau dan tanggal persetujuan | |

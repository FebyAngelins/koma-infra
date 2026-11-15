# Modul 04 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | k01 Klinik Sehat Lampung |
| Peninjau PR `m04` (NIM) | - (tugas individu) |

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
| 2 | C.5.3 | + bucket arsip, laporan v1 | 15 Nov | tidak terambil: `403 Forbidden` |
| 3 | D.3.3 | volume sama + db baru, laporan v2 | 15 Nov | tidak terambil: `403 Forbidden` |
| 4 | E.2 | bersih (bucket state tetap) | 15 Nov | tidak terambil: `403 Forbidden` |
| 5 | Tugas Langkah 3 | nilai kasus, versi 4.2.0 | 15 Nov | tidak terambil: `403 Forbidden` |
| 6 | Tugas Langkah 4 | nilai kasus, versi 4.3.0 | 15 Nov | tidak terambil: `403 Forbidden` |
| 7 | Tugas Langkah 5 | bersih lagi | 15 Nov | tidak terambil: `403 Forbidden`; bukti manual `describe-volumes` tag modul=m04 → `[]` |

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
| Nama bucket arsip (dengan `<akun>`) | `koma-123450039-m04-arsip-<akun>` |
| Ringkasan plan C.5.1 | `Plan: 6 to add, 0 to change, 0 to destroy.`; `Apply complete! Resources: 6 added` (bucket, versioning, enkripsi, blok publik, lifecycle, objek laporan) |
| Tiga aturan lifecycle (C.5.2) | `versi-lama Enabled` (semua objek, noncurrent 30 hari); `laporan-dingin Enabled laporan/` (transisi STANDARD_IA hari ke-30); `sementara Enabled tmp/` (kedaluwarsa 7 hari) |
| Versi laporan setelah C.5 | 1 versi: `laporan/ringkasan-harian.csv` VersionId `SubK.JUnDg1XOQO4.UGWIdqzX7yv.BBY`, IsLatest `True`, 64 byte |
| Jumlah versi state pada potret 2 | 4 versi `m04/data.tfstate` (migrasi B.4, plan dan apply B.5, apply C.5.1); potret 2 sendiri tidak terambil (`403`) |

Mengapa aturan `laporan-dingin` tidak akan memindahkan objek laporan Anda: objek laporan hanya 64 byte, jauh di bawah ukuran minimum 128 KB yang dipindahkan lifecycle ke STANDARD_IA, sehingga S3 melewatinya (memindahkan objek sekecil itu justru lebih mahal karena IA menagih minimal 128 KB per objek).

## Catatan Bagian D

| Hal | Sebelum (B.5) | Sesudah (D.3) |
|---|---|---|
| ID server db | `i-0c929243b1f21ce62` | `i-0881493f07b107c54` (server pengganti percobaan pertama `i-0e8ae2611edd49c17` diganti lagi, lihat catatan di bawah) |
| ID volume data | `vol-0dc22177bf89c8b7f` | `vol-0dc22177bf89c8b7f` (sama) |
| Baris `KOMA-PENANDA` | `dibuat_oleh=i-0c929243b1f21ce62 waktu=2026-11-15T13:50:56Z sekarang=i-0c929243b1f21ce62 versi=4.0.0 baris_riwayat=1` | `dibuat_oleh=i-0c929243b1f21ce62 waktu=2026-11-15T13:50:56Z sekarang=i-0881493f07b107c54 versi=4.1.0 baris_riwayat=2` (muncul 21:37:16 WIB) |
| Versi laporan (jumlah) | 1 | 2: `M7IOHktXLhNUWcZJv8B3JMmIKh2SnuW1` (IsLatest `True`, 4.1.0) dan `SubK.JUnDg1XOQO4.UGWIdqzX7yv.BBY` (`False`, 4.0.0), masing-masing 64 byte |

| Hal | Isi |
|---|---|
| Ringkasan plan D.1 (apakah `aws_ebs_volume.data` muncul?) | `Plan: 2 to add, 1 to change, 2 to destroy.`: `aws_instance.db must be replaced` (`user_data # forces replacement`, versi 4.0.0 → 4.1.0), `aws_volume_attachment.data must be replaced` (`instance_id # forces replacement`), `aws_s3_object.laporan will be updated in-place`. `aws_ebs_volume.data` tidak muncul (hanya `Refreshing state`) |
| Durasi `Destruction complete` attachment dan server, `Creation complete` server dan attachment | penggantian bersih (Tugas Langkah 4, 4.2.0 → 4.3.0): attachment 32 s, server 11 s, server baru 15 s, attachment baru 22 s = 80 s. Penggantian D.2 (4.0.0 → 4.1.0): attachment 26 s, server 10 s, server baru 16 s, lalu terputus `ExpiredToken` (lihat catatan insiden) |
| Jam menjawab `yes` dan jam penanda server baru muncul | Langkah 4: perintah apply 22:49:28 WIB (yes beberapa detik kemudian), penanda server baru terbaca pada percobaan pertama 22:52:00 WIB. D.3: penanda server pengganti terbaca 21:37:16 WIB setelah pemulihan |
| RTO penggantian server db (menit:detik) | ±2:32 (22:49:28 → 22:52:00), diukur pada penggantian bersih Tugas Langkah 4 karena penggantian D.2 terganggu kredensial kedaluwarsa; terhadap E4 99,95% (±21,6 menit per 30 hari) satu penggantian memakai ±12% anggaran |
| `volume_selamat` dan `arsip_berversi` pada potret 3 | tidak terbaca (`403 Forbidden`). Bukti manual: volume `vol-0dc22177bf89c8b7f` sama sebelum dan sesudah dengan server berbeda, penanda `baris_riwayat=2`; laporan 2 versi |

Apa yang diganti, apa yang tetap, dan apa arti `dibuat_oleh` serta `baris_riwayat`: yang diganti adalah server db dan attachment-nya (dan versi objek laporan bertambah), yang tetap adalah volume `vol-0dc22177bf89c8b7f` beserta isinya. `dibuat_oleh=i-0c929243b1f21ce62` masih menyebut server pertama karena `penanda.txt` hanya ditulis bila belum ada dan volume tidak diformat ulang (`blkid` menemukan sistem berkas), sedangkan `sekarang` adalah server baru. `baris_riwayat=2` berarti dua boot yang berhasil memasang volume pernah menulis ke `riwayat.txt`: server pertama (4.0.0) dan server pengganti (4.1.0).

Insiden saat D.2 (15 Nov 2026): apply pertama pukul 21:14:49 WIB melepas attachment (26 s), menghapus server lama (10 s), dan membuat `i-0e8ae2611edd49c17` (16 s), lalu kredensial sesi kedaluwarsa saat attachment baru dibuat. State gagal diunggah (`ExpiredToken`) dan ditulis ke `errored.tfstate`, kunci `m04/data.tfstate.tflock` tertinggal (ID `30a83b4f-…`, Who `angels@MacBook-Air-Feby.local`, OperationTypeApply, 14:14:54 UTC). Pemulihan: kredensial disegarkan, `tofu force-unlock 30a83b4f-…` (sah karena kunci milik apply sendiri yang gagal dan tidak ada operasi lain), `tofu state push errored.tfstate`, lalu plan `1 to add` (attachment) dan apply. Server itu melapor `KOMA-PENANDA galat: volume … belum terpasang` karena skripnya sudah menyerah sebelum attachment ada, sehingga diganti sekali lagi dengan `tofu apply -replace=aws_instance.db` menjadi `i-0881493f07b107c54`, yang berhasil memasang volume lama tanpa memformatnya.

## Catatan Bagian E

| Hal | Isi |
|---|---|
| Ringkasan `tofu destroy` stack `m04-data` | |
| `tofu state list` sesudah destroy; apakah `m04/data.tfstate` masih ada di bucket | `m04/data.tfstate` tetap ada di bucket state dengan 19 versi (sebelumnya 16): state yang benar sesudah destroy adalah state kosong, bukan state yang hilang |
| `bersih_akhir` dan `Tugas lulus` pada potret 4 | tidak terambil: `koma cek m04` → `verifier menolak (403): Forbidden`. Bukti manual: `describe-volumes` tag modul=m04 → `[]` |
| `koma sisa`: resource bertag, fondasi, instance tanpa `managed-by` | 8 ARN bertag (4 instance dan 4 volume yang baru dihapus, jeda daftar tag sekitar 1 jam; `describe-volumes` sudah kosong); Fondasi 1: `koma-123450039-tfstate-<akun>`; instance tanpa `managed-by` 0; snapshot sisa AMI 0 |

Mengapa bucket state tidak ikut dibongkar (satu sampai dua kalimat): bucket state milik stack fondasi `m00-state` yang hidup selama kursus, dan ia menyimpan state (kosong) serta riwayat versi `m04-data` yang dibaca lagi oleh apply berikutnya di Tugas dari komputer mana pun; menghapusnya berarti kehilangan catatan dan riwayat itu, dan bucket kosong praktis tidak menambah tagihan.

## Catatan Tugas

Pemetaan data kasus (rujuk Tabel S kasus kelompok):

| Data | Fakta kasus (angka) | Model akses | Layanan AWS | Dibangun di modul ini? | Alasan |
|---|---|---|---|---|---|
| S1 | Database RME relasional 6,8 TB, tumbuh 1,9 TB/tahun; disk lokal server primer, replika asinkron ke Metro (lag 40 s) | block | EBS (gp3 untuk volume data, io2 bila IOPS tinggi), satu volume per server db, dipisah dari volume log | ya: `aws_ebs_volume.data` (4 GiB mewakili 4 TB) | relasional, ditulis acak oleh satu server db dengan unit blok; S6: volume log penuh menghentikan RME 190 menit, jadi ukuran ditulis di kode; S8 memisahkan volume database dari server |
| S2 | SOP, formulir persetujuan, kontrak asuransi ±9 TB pada dua NAS lewat SMB; dibaca semua klinik | file | Amazon FSx for Windows File Server (SMB); EFS bila klien NFS | tidak | dibaca bersama oleh banyak klien sebagai berkas dan folder lewat SMB; aplikasi dan pengguna klinik memakai jalur berkas, bukan API objek |
| S3 | Log audit dan event kunjungan ±65 GB/hari, disimpan 6 tahun; data mart mutu 3,4 TB | object (log); block/warehouse untuk data mart | S3 dengan prefix per tanggal dan lifecycle ke Glacier untuk 6 tahun; data mart di gudang data | tidak (pola sama dengan bucket arsip) | log ditulis sekali dan dibaca pipeline analytics; retensi 6 tahun cocok dengan kelas dingin S3; E8/S8 memindahkan arsip ter-pseudonim ke cloud publik |
| S4 | Hasil lab PDF, foto klinis, rujukan ±150 TB, tumbuh 4 TB/bulan; tidak pernah diubah setelah ditandatangani dan tidak boleh tertimpa | object | S3 berversi + lifecycle (+ Object Lock untuk berkas bertanda tangan) | ya: `aws_s3_bucket.arsip` berversi (retensi 90 hari) | setiap berkas utuh, ditulis sekali dan diambil lewat aplikasi web; S8 merencanakan object storage kompatibel S3 dengan versioning; versioning menyimpan versi lama bila tertimpa |
| S5 (apa yang dicakup versioning, apa yang tidak) | Backup penuh mingguan dan inkremental harian ke NAS di ruangan yang sama; tape bulanan ke Metro; restore penuh belum diuji | — | snapshot EBS terjadwal ke region/akun lain (AWS Backup); replikasi S3 lintas region | versioning saja | versioning mencakup penimpaan dan penghapusan objek S4 selama 90 hari; tidak mencakup volume database S1 (butuh snapshot), bucket atau akun yang terhapus atau region terganggu, kerusakan yang ditulis sebagai versi baru setelah retensi lewat, dan konsistensi database; S6 menunjukkan backup harus diuji restore |

| Hal | Isi |
|---|---|
| `ukuran_data_gib` di `kasus.tfvars` dan hitungannya (1 GiB = 1 TB, ≤ ±70%; rujuk `K-04-…`) | `4` (batas praktikum), K-04-001: S1 6,8 TB > 2,8 TB; 6,8 / 0,7 ≈ 9,7 TB dibutuhkan hari ini |
| `retensi_versi_hari` di `kasus.tfvars` dan alasannya (rujuk `K-04-…`) | `90`, K-04-002: tiga siklus tape bulanan S5 untuk menyadari dan memulihkan penimpaan tidak sengaja S4; S6 restore korup; biaya versi kecil karena S4 hampir tidak pernah ditimpa |
| Bila S1 > 2,8 TB: apa yang dibutuhkan sistem sesungguhnya | sekurangnya ≈ 9,7 TB hari ini dan ≈ 17,9 TB untuk tiga tahun (12,5 TB / 0,7); melebihi batas satu volume gp3 (16 TiB), sehingga perlu beberapa volume (striping/LVM) atau layanan database terkelola, volume log transaksi terpisah dengan alarm pemakaian (S6), dan snapshot terjadwal |
| Komputer tempat Tugas dikerjakan (sama dengan sesi kelas?) | laptop pribadi yang sama dengan sesi, 15 Nov 2026 |
| Ringkasan plan Langkah 3 (`size`, `noncurrent_days`) | `tofu plan -var-file=kasus.tfvars`: `9 to add` dengan `size = 4` dan `noncurrent_days = 90`; apply `9 added`; server `i-09422d10cbcb47326` tanpa IP publik (`None`). Langkah 4 (4.2.0 → 4.3.0): `Plan: 2 to add, 1 to change, 2 to destroy.` tanpa `aws_ebs_volume.data`; `Apply complete! Resources: 2 added, 1 changed, 2 destroyed.` |
| Penanda Langkah 3 dan Langkah 4 | Langkah 3: `KOMA-PENANDA dibuat_oleh=i-09422d10cbcb47326 waktu=2026-11-15T15:41:21Z sekarang=i-09422d10cbcb47326 versi=4.2.0 baris_riwayat=1` (volume baru `vol-08f2af5a3bdc9ef3b`); Langkah 4: `KOMA-PENANDA dibuat_oleh=i-09422d10cbcb47326 waktu=2026-11-15T15:41:21Z sekarang=i-0c7d668ed9646ac72 versi=4.3.0 baris_riwayat=2` (volume sama `vol-08f2af5a3bdc9ef3b`) |
| Hasil potret 5, 6, dan 7 | ketiganya `verifier menolak (403): Forbidden` (15 Nov), dilewati seperti Modul 03. Setelah `tofu destroy -var-file=kasus.tfvars`: `describe-volumes` tag modul=m04 kosong, `koma sisa` hanya menyisakan bucket state di Fondasi (11 ARN bertag adalah instance dan volume yang baru dihapus, jeda daftar tag ±1 jam), instance tanpa `managed-by` 0 |
| Tautan *pull request* `modul-04` → `main` | https://github.com/FebyAngelins/koma-infra/pull/4 |
| NIM peninjau dan tanggal persetujuan | tanpa peninjau: tugas individu (seperti Modul 03, atas arahan dosen); di-merge sendiri 15 Nov 2026 |

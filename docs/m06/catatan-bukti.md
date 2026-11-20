# Modul 06 — Catatan Bukti

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung (KSL) |
| Peninjau PR `m06` (NIM) | - (tugas individu, tanpa peninjau sesuai arahan dosen) |
| Tautan *pull request* | |

Isi berkas ini sambil mengerjakan prosedur. Angka, ID, dan waktu disalin dari keluaran perintah Anda sendiri; contoh di naskah hanya gambaran. Jangan menulis token verifier, isi state, atau 12 digit ID akun AWS (tulis `<akun>`); ID resource (`i-…`, `sg-…`) dan nama DNS ALB boleh ditulis. Berkas ini ikut di-commit dan masuk `koma-module-06.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `tofu apply` stack `m00-verifier` setelah `izin-m06.tf` (ringkasan) | |
| Impor yang diperlukan di `m00-verifier` (bila ada) | |
| `koma ip` saat `koma legacy buat` (bentuk `x.x.x.x/32`) | `103.211.143.242/32` |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | laptop pribadi (MacBook Air) |
| Ambang jeda dan jendela peralihan kasus (L4, L3) | L4: jeda per peralihan paling lama 2 detik, karena kios menampilkan galat setelah 3 detik; jendela pemeliharaan Selasa 01.00–04.00, maksimal 30 menit. L3: jam paling sepi 00.00–05.00. |
| SLA/SLO kasus (E4, E5, O1) dan anggaran galat per 30 hari (hitungan) | SLA 99,95% (E4, O1); SLO p95 < 500 ms (E5); target tingkat galat ≤ 0,05%. Anggaran: (1 − 0,9995) × 30 × 24 × 60 = 0,0005 × 43.200 menit = 21,6 menit per 30 hari. |
| Lama insiden O5 kasus sampai ada yang tahu | 25 menit sampai ada yang tahu, sekitar 116% dari anggaran 21,6 menit (25 / 21,6). |

## Catatan Bagian A — Inventarisasi

| Hal | Isi |
|---|---|
| ID server, SG, dan aturan legacy (`koma legacy info`) | server `i-0dc7c89eebf627ea2` (running, IP publik 13.211.103.124); SG `sg-030b76f1f94f7d428`; aturan HTTP 80 `sgr-09f741338bd01b56a` dari `103.211.143.242/32`. `koma sehat` ke IP legacy SEHAT dalam 0,4 detik; `/versi` = `0.9.0`, peran `legacy`. |
| Atribut yang harus sama di kode (nama dan deskripsi SG, sumber dan deskripsi aturan, tipe, tag) | SG: nama `koma-123450039-m06-legacy`, deskripsi `Web lama koma-api (dibuat manual)`, VPC bawaan `vpc-0c08be8489ab1db4d`. Aturan: `tcp` 80–80 dari `103.211.143.242/32`, deskripsi `HTTP dari kantor`. Server: `t3.micro`, AMI `ami-052190d76c25f66d1`, subnet `subnet-0b2c0283634e183e2`. Tag: `Name`, `kelompok`, `kursus`, `modul`, `nim`, `peran = legacy`, `versi = 0.9.0`. |
| Yang dapat diketahui dari AWS tentang server ini | tipe, AMI, subnet, VPC, SG dan aturannya, IP publik dan privat, opsi metadata (IMDS), tag, waktu peluncuran, status, serta isi `user_data` dan keluaran konsol. |
| Yang tidak dapat diketahui dari AWS | siapa yang membuat dan mengapa, perubahan apa yang pernah dilakukan dengan tangan di dalam server, siapa saja pengguna yang memakai alamatnya (di kasus: 140 kios dengan alamat di firmware, L2), data apa yang ditulis dan ke mana (L5), serta apakah ada ketergantungan lain yang tidak terlihat dari luar. |
| Temuan lain (IMDS, aturan keluar bawaan) | IMDS `HttpTokens = required` (berbeda dengan contoh naskah yang `optional`); aturan keluar bawaan `sgr-0d254039912d55f8a` semua protokol ke `0.0.0.0/0`, tidak ditulis di kode dan tidak diimpor; disk root tidak terenkripsi. |

**Matriks Strategi** (kasus kelompok; satu baris per komponen)

| Komponen (kode bukti) | Strategi | Alasan |
|---|---|---|
| Sistem Antrean Pendaftaran v0.9 di server lama (L1) | rehost dulu (diimpor ke kode tanpa diubah), lalu replatform ke server hijau di balik ALB | Masih dipakai setiap hari, jadi retire belum bisa. Alamatnya tertanam di firmware 140 kios dan butuh sekitar 3 bulan untuk diperbarui (L2), sehingga alamat harus tetap dan peralihan harus di bawah 2 detik (L4). ALB menjadi alamat tetap; versi baru dibangun dari kode dengan IMDSv2, disk terenkripsi, dan log terkelola. |
| Server legacy setelah peralihan (L1) | retire | Setelah listener pindah ke hijau dan kriteria contract terpenuhi, server lama hanya memakan biaya dan membawa utang (disk tidak terenkripsi, dibuat tangan). Dibongkar lewat kode (`pertahankan_legacy = false`). |
| Database RME (E1, E8, P4) | retain | Rekam medis tetap di pusat data on-premises sesuai rencana E8 dan aturan bahwa identitas pasien tidak keluar dari pusat data (P4, A2). Data tidak dipindahkan di modul ini; versi baru tetap memakai database yang sama. |
| Analytics dan arsip ter-pseudonim (E8, S3) | replatform ke cloud publik (object storage dan gudang data) | E8 merencanakan arsip dan data ter-pseudonim pindah ke cloud publik; log ditulis sekali dan dibaca pipeline sehingga cocok dengan object storage berlifecycle, tanpa mengubah logika analisisnya. |
| Portal pasien dan dasbor klinik (E1) | rehost sekarang, refactor ditinjau di Modul 08 | Komponen web tanpa data rahasia di servernya dan bebannya naik saat jam sibuk (O3: normal 90 rps, puncak 420 rps), sehingga kelak cocok untuk container dan autoscaling; mengubah kode sekarang tidak sebanding dengan risikonya. |

## Catatan Bagian B — Impor

| Hal | Isi |
|---|---|
| Ringkasan plan impor (`N to import, N to add, N to change, N to destroy`) | `Plan: 3 to import, 0 to add, 3 to change, 0 to destroy.` |
| Perubahan in-place yang diusulkan (resource dan tag) | `aws_security_group.legacy[0]`, `aws_vpc_security_group_ingress_rule.legacy_http[0]`, dan `aws_instance.legacy[0]`: hanya `tags`/`tags_all`, penambahan tag dari `default_tags` provider yang belum dipasang `koma legacy buat` (`stack = m06-migrasi`, `managed-by = opentofu`). Tidak ada `-/+` maupun penggantian. |
| Atribut yang sempat membuat plan tidak bersih dan cara memperbaikinya | `cidr_saya` di `terraform.tfvars` masih `GANTI/32` sehingga validasi variabel gagal; diisi `103.211.143.242/32`, sama dengan sumber aturan HTTP 80. Plan pertama hanya `2 to import` karena `impor.tf` belum memuat blok server; plan lama dihapus dan dibuat ulang setelah tiga blok import lengkap. AMI, `user_data`, dan `user_data_base64` di-`ignore_changes` supaya server tidak diganti. Satu kali plan gagal karena token AWS kedaluwarsa (`ExpiredToken`), diperbaiki dengan `aws logout` lalu `aws login`. |
| Plan setelah apply dan `impor.tf` dihapus | `No changes. Your infrastructure matches the configuration.`; `koma legacy info` menyatakan `Dikelola kode : ya`. |

## Catatan Bagian C — Expand dan alih versi

| Hal | Isi |
|---|---|
| Plan expand (ringkasan) | `Plan: 18 to add, 0 to change, 0 to destroy.`; tidak ada resource legacy di daftar `~`, `-/+`, atau `-`; output `aktif = "biru"`, `log_group = "/koma/123450039/m06/api"`. |
| `alb_url` | `http://koma-123450039-m06-625072480.ap-southeast-2.elb.amazonaws.com` (server hijau `i-0f1604634fc677876`) |
| `koma sehat` ke ALB (detik) dan `/versi` setelah expand | `SEHAT setelah 0.7 detik`; `/versi` = `{"versi": "0.9.0", "peran": "legacy", "host": "ip-172-31-35-136…"}`, jadi lalu lintas masih ke legacy. |
| Status target biru dan hijau | biru `i-0dc7c89eebf627ea2` `healthy`; hijau `i-0f1604634fc677876` `unused` (alasan `Target.NotInUse`): target group hijau belum dirujuk listener sehingga ALB belum menjalankan health check padanya. Kesiapan hijau dipastikan lewat penanda konsol sebelum alih. |
| Plan alih (resource yang berubah) | `Plan: 0 to add, 1 to change, 0 to destroy.` Hanya `aws_lb_listener.http` (in-place): `default_action.target_group_arn` dari `targetgroup/koma-123450039-m06-biru/…` ke `targetgroup/koma-123450039-m06-hijau/…`; output `aktif = "biru" -> "hijau"`. |
| Ringkasan `koma probe` saat alih biru → hijau (sampel, gagal, jeda terpanjang, versi, detik alih) | Percobaan 1 (gagal): `Sampel 236, gagal 87, jeda terpanjang 45.0 dtk, versi {'0.9.0': 149}, alih pada detik None`; GAGAL mulai detik 75,1. Target hijau `unhealthy` (`Target.FailedHealthChecks`) dan ALB menjawab `502 Bad Gateway`: ALB menjangkau server, tetapi tidak ada yang menjawab di port 80. Log group kosong (tanpa stream), sehingga layanan `koma-api` tidak pernah menulis log. Rollback `aktif = "biru"` (1 change pada listener) memulihkan `/versi` ke `0.9.0` legacy. Perbaikan: unit memakai pengguna sistem `koma` dan folder `/var/log/koma` disiapkan sebelum layanan start, ditambah aturan listener `X-Koma-Uji: hijau` agar hijau diuji ALB sebelum alih. Percobaan 2 (setelah perbaikan dan uji hijau sehat): `Sampel 235, gagal 0, jeda terpanjang 0.0 dtk, versi {'0.9.0': 158, '6.0.0': 77}, alih pada detik 80.8`. Plan alih kedua sempat `2 to add, 1 to change, 2 to destroy` karena AMI `most_recent` bergeser; tidak di-apply, `ignore_changes = [ami]` ditambahkan pada server hijau sampai plan `0 to add, 1 to change, 0 to destroy`. |
| Waktu alih (WIB) dan perbandingan dengan L4 | Percobaan 1: apply alih 10.57 WIB, gagal; jeda 45 detik jauh melampaui L4 (≤ 2 detik, kios galat setelah 3 detik) sehingga untuk KSL ini setara insiden, lalu di-rollback. Percobaan 2: apply alih sekitar 11.27–11.28 WIB, alih berhasil dengan 0 gagal dan jeda terpanjang 0,0 detik, di bawah L4 (≤ 2 detik); di produksi KSL alih dijadwalkan di jendela Selasa 01.00–04.00 (L4) pada jam sepi 00.00–05.00 (L3). Rollback ke biru sudah terlatih (1 change pada listener, `/versi` kembali `0.9.0`). |
| Penanda konsol server hijau | Server hijau pertama (`i-0f1604634fc677876`): `KOMA-PENANDA hijau 6.0.0 siap, log ke /koma/123450039/m06/api` tercetak walau layanan tidak menjawab, jadi penanda hanya membuktikan cloud-init selesai. Setelah perbaikan (`i-0fea7f04887c849be`): `KOMA-PENANDA layanan koma-api active`, `systemd[1]: Started koma-api.service - koma-api 6.0.0.`, `KOMA-PENANDA hijau 6.0.0 siap, log ke /koma/123450039/m06/api`. Uji lewat aturan listener `X-Koma-Uji: hijau` menjawab `{"versi": "6.0.0", "peran": "hijau"}` dan target `healthy` sebelum alih, sementara permintaan biasa tetap `0.9.0`. |

## Catatan Bagian D — Observability

| Hal | Isi |
|---|---|
| Stream log dan contoh baris log dari CloudWatch Logs (tanpa data pribadi) | Stream `i-0fea7f04887c849be` (ID server hijau). Contoh: `2026-11-19T04:32:08.225000+00:00 i-0fea7f04887c849be 172.31.10.94 "GET /health HTTP/1.1" 200 -` dan `2026-11-19T04:32:13.612000+00:00 i-0fea7f04887c849be 172.31.36.152 "GET /health HTTP/1.1" 200 -`. Alamat sumber adalah IP privat dua node ALB (health check bergantian sekitar tiap 5 detik), bukan IP laptop. Server hijau pertama tidak pernah membuat stream karena layanannya gagal start. |
| Plan observability (ringkasan) | `Plan: 2 to add, 2 to change, 0 to destroy.` Ditambah `aws_cloudwatch_metric_alarm.latensi` (`koma-123450039-m06-latensi-p95`, `AWS/ApplicationELB` `TargetResponseTime`, dimensi `LoadBalancer = app/koma-123450039-m06/69f882f265f15073`, p95, 60 dtk, 1 periode, ambang 0.3, `notBreaching`) dan `aws_cloudwatch_dashboard.api`. Dua perubahan in-place karena IP laptop berganti antarhari (`103.211.143.242/32` → `118.99.119.185/32`): `cidr_ipv4` pada `alb_http` dan `legacy_http[0]` (Tabel 6.14, IP berubah setelah impor); tanpa penggantian. |
| Ringkasan `koma beban` (permintaan, gagal, p50, p95) | `Permintaan 943, gagal 0, p50 740 ms, p95 830 ms` (4 pekerja, `/lambat?ms=500`, 180 detik; diukur dari laptop, termasuk jaringan Indonesia–Sydney). p95 `TargetResponseTime` di CloudWatch sekitar 0,50–0,51 detik per menit selama beban. Beban dijalankan dua kali; `RequestCount` per menit 158, 313, 312, 151 pada 19.31–19.34 dan lagi mulai 19.49. |
| Beban dimulai dan berhenti (WIB) | Beban 1: sekitar 19.30.30–19.33.30. Beban 2: sekitar 19.49–19.52 (20 November 2026). |
| Waktu alarm berubah ke `ALARM` dan kembali `OK` (dari riwayat alarm) | `INSUFFICIENT_DATA → OK` 19.30.41; `OK → ALARM` 19.34.41; `ALARM → OK` 19.43.41; `OK → ALARM` 19.52.41; `ALARM → OK` 20.01.41 (WIB). |
| Waktu deteksi (menit) dibandingkan O5 dan anggaran O1 | Sekitar 4 menit (4,2 dan 3,7 menit) dari beban dimulai sampai `ALARM`, sekitar 19% anggaran 21,6 menit; insiden O5 (25 menit) sekitar 116%. Pemulihan ke `OK` sekitar 9–10 menit setelah beban berhenti. Ambang 0,3 detik lebih ketat 0,2 detik dari SLO E5 (p95 < 500 ms). |

## Catatan Bagian E — Drift

| Hal | Isi |
|---|---|
| Garis dasar `tofu plan -detailed-exitcode` (exit code) | `No changes. Your infrastructure matches the configuration.`, `exit code = 0` (setelah apply observability dan pembaruan `cidr_saya`). |
| Perintah yang menyuntikkan drift | `aws ec2 create-tags --resources i-0fea7f04887c849be --tags Key=diubah-manual,Value=ya` pukul 20.25 WIB (20 November 2026), tanpa keluaran. |
| `tofu plan -detailed-exitcode` setelah drift: exit code dan ringkasan | `aws_instance.hijau will be updated in-place`: `tags` dan `tags_all` `- "diubah-manual" = "ya" -> null`; `Plan: 0 to add, 1 to change, 0 to destroy.`; `exit code = 2`. |
| `tofu plan -refresh-only`: apa yang ditampilkan | `Note: Objects have changed outside of OpenTofu`, `aws_instance.hijau has changed`: `+ "diubah-manual" = "ya"`; diakhiri `This is a refresh-only plan, so OpenTofu will not take any actions to undo these.` Laporan itu juga memuat tiga perubahan yang bukan drift: `aws_security_group.alb` dan `aws_security_group.legacy[0]` (atribut `ingress` versi lama di state berubah dari `103.211.143.242/32` ke `118.99.119.185/32`, karena aturan diubah lewat resource aturan terpisah) dan `aws_cloudwatch_metric_alarm.latensi` (daftar aksi kosong `[]` terbaca untuk pertama kali). Ketiganya tidak membuat plan biasa mengusulkan perubahan; hanya tag `diubah-manual` yang merupakan drift sungguhan. `tofu apply -refresh-only` tidak dijalankan. |
| Keputusan (kode diubah atau kenyataan dikembalikan) dan alasannya | Kenyataan dikembalikan ke kode lewat `tofu apply`. Tag `diubah-manual` tidak punya alasan, pemilik, atau catatan; mempertahankannya lewat `apply -refresh-only` hanya menyalinnya ke state sementara kode tetap tidak memuatnya, sehingga apply berikutnya akan membatalkannya diam-diam. Ini pola insiden O5 KSL (perubahan manual di konsol tanpa catatan): perubahan yang memang perlu harus masuk lewat kode dan review. |
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
| 1 | A.3 | legacy dibuat, belum diimpor | | verifier menolak (403); potret dilewati sesuai arahan dosen |
| 2 | B.5 | legacy diimpor | | verifier menolak (403): Forbidden; potret dilewati sesuai arahan dosen |
| 3 | C.7 | expand, listener ke biru | | verifier menolak (403): Forbidden; potret dilewati sesuai arahan dosen |
| 4 | C.8 | alih, listener ke hijau | | |
| 5 | D.6 | alarm pernah menyala | | |
| 6 | E.2 | drift disuntikkan | | |
| 7 | E.4 | drift direkonsiliasi | | |
| 8 | G.2 | kosong (sesi kelas) | | |
| | Tugas | | | |
| | Tugas | | | |
| | Tugas | contract | | |
| | Tugas | kosong | | |

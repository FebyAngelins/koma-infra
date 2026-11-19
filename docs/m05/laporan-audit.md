# Modul 05 — Laporan Audit Keamanan

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | k01 Klinik Sehat Lampung |
| Peninjau PR `m05` (NIM) | - (tugas individu) |
| Tautan *pull request* | https://github.com/FebyAngelins/koma-infra/pull/5 (tanpa peninjau: tugas individu atas arahan dosen) |

Isi berkas ini sambil mengerjakan prosedur. Jangan menulis password, passphrase state, token verifier, isi state atau plan JSON, atau 12 digit ID akun AWS; tulis nama bucket sebagai `koma-<nim>-m05-laporan-<akun>`. Berkas ini ikut di-commit dan masuk `koma-module-05.zip`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| `tofu apply` stack `m00-pagar` (ringkasan baris terakhir) | `Plan: 1 to add` (`aws_s3_account_public_access_block.akun`), apply `1 added` |
| `aws s3control get-public-access-block` (keempat pengaturan) | `BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, `RestrictPublicBuckets` semuanya `true` (sebelum apply: `NoSuchPublicAccessBlockConfiguration`) |
| `tofu apply` stack `m00-verifier` setelah `izin-m05.tf` (ringkasan) | `Plan: 1 to add` (`aws_iam_role_policy.baca_m05`); `list-role-policies`: `koma-baca-daftar-objek`, `koma-baca-keamanan`, `koma-baca-metadata` |
| Impor yang diperlukan (bila ada) | tidak ada (state `m00-verifier` ada di laptop ini) |
| Sidik jari passphrase state (8 karakter awal SHA-256, bukan passphrase-nya) | `64d32c5c` |
| Tempat Anda menyimpan salinan passphrase (jenis, bukan isinya) | |
| Komputer yang dipakai sesi ini (PC lab nomor / laptop) | laptop pribadi (macOS), 19 Nov 2026 |
| `conftest --version`, `trivy --version` | Conftest 0.71.1 (OPA 1.21.1), Trivy 0.76.2 |

## Tabel Audit

Satu baris per temuan stack `m05-rawan` (ada enam). Nomor baris merujuk berkas di `stacks/m05-rawan/`.

| # | Temuan (berkas:baris) | Kebutuhan dilanggar | Ancaman ([S] §6.4, hlm.) | Perbaikan di `m05-aman` |
|---|---|---|---|---|
| 1 | `variables.tf:27-31` password basis data ditulis di kode sebagai `default = "koma123"` dan ikut ke repo Git | kerahasiaan (siapa pun yang membaca repo atau pull request tahu password), akuntabilitas (tidak bisa dirotasi tanpa mengubah kode) | data breach (hlm. 195); misconfiguration (hlm. 220) | `random_password` dibangkitkan saat apply, disimpan di Parameter Store sebagai `SecureString` dengan kunci KMS sendiri; tidak ada nilai di repo |
| 2 | `templates/cloud-init.yaml.tftpl:17` dan `main.tf:95-99` password dirender ke `user_data` (`Environment=KOMA_DB_PASSWORD=koma123`), terlihat utuh di plan dan bisa dibaca lewat `ec2:DescribeInstanceAttribute` | kerahasiaan (siapa pun dengan hak baca EC2, termasuk role verifier `ec2:Describe*`, membaca password) | insider threat (hlm. 205); ancaman API cloud (hlm. 205) | `user_data` hanya memuat nama parameter; server mengambil nilainya sendiri dari Parameter Store saat boot lewat role IAM |
| 3 | `outputs.tf:5-7` output `db_password` tanpa `sensitive = true` sehingga tercetak di layar (`db_password = "koma123"`), log terminal, dan state | kerahasiaan, akuntabilitas (rahasia tersebar ke log dan tangkapan layar yang tidak terkendali) | data breach (hlm. 195) | output password dihapus; output hanya alamat API, nama bucket, dan nama parameter (C.7) |
| 4 | `main.tf:36-47` kebijakan role server `Action = "*"`, `Resource = "*"` ("supaya tidak repot soal izin") | otorisasi (least privilege), integritas (server yang disusupi dapat mengubah atau menghapus apa pun di akun) | ancaman API cloud (hlm. 205); insider threat (hlm. 205) | kebijakan hanya `ssm:GetParameter` pada satu parameter dan `kms:Decrypt` pada satu kunci milik sendiri |
| 5 | `main.tf:63-70` SSH port 22 dari `0.0.0.0/0` (ditambah HTTP dari `0.0.0.0/0` di `main.tf:72-79` dan IP publik di `main.tf:92`) | otorisasi (siapa pun di internet dapat mencoba masuk), ketersediaan (brute force dan pemindaian) | ancaman server dan jaringan (hlm. 197–204) | tanpa SSH, key pair, atau port admin; HTTP hanya dari `cidr_saya` (/32); keluar hanya HTTPS ke layanan yang perlu |
| 6 | `main.tf:113-134` bucket laporan publik: keempat blok publik `false` dan bucket policy `Principal = "*"` `s3:GetObject`, berisi objek `kelas_data` rahasia (`main.tf:136-141`), tanpa kunci KMS sendiri | kerahasiaan, privasi (laporan pelanggan bisa diunduh siapa pun yang tahu URL) | data breach (hlm. 195); misconfiguration dan data exfiltration (hlm. 220–221) | keempat blok publik `true` (ditambah pagar akun `m00-pagar`), enkripsi SSE-KMS dengan kunci sendiri, bucket policy menolak akses tanpa TLS |

## Hasil Trivy

Perintah yang dijalankan dan versinya: `trivy config -q .` di `stacks/m05-rawan` dengan Trivy 0.76.2 (12 temuan: CRITICAL 1, HIGH 8, MEDIUM 1, LOW 2).

Satu baris per ID temuan. Untuk `m05-aman`, tulis temuan yang diterima lewat `trivy:ignore` beserta alasannya.

| Stack | ID temuan | Severity | Sesuai temuan Tabel Audit no. (atau "tambahan") | Relevan? Alasan |
|---|---|---|---|---|
| `m05-rawan` | AWS-0028 | HIGH | tambahan | ya: tanpa IMDSv2, SSRF di API dapat mencuri kredensial role server |
| `m05-rawan` | AWS-0086 | HIGH | 6 | ya: blok publik tidak menolak ACL publik |
| `m05-rawan` | AWS-0087 | HIGH | 6 | ya: blok publik tidak menolak bucket policy publik |
| `m05-rawan` | AWS-0089 | LOW | tambahan | sebagian: log akses bucket membantu akuntabilitas, tetapi bukan penyebab kebocoran |
| `m05-rawan` | AWS-0090 | MEDIUM | tambahan | sebagian: versioning menjaga integritas laporan, tidak terkait kerahasiaan |
| `m05-rawan` | AWS-0091 | HIGH | 6 | ya: ACL publik lama tidak diabaikan |
| `m05-rawan` | AWS-0093 | HIGH | 6 | ya: bucket berkebijakan publik tidak dibatasi |
| `m05-rawan` | AWS-0104 | CRITICAL | tambahan | sebagian: keluar ke mana saja memudahkan exfiltration dari server yang disusupi |
| `m05-rawan` | AWS-0107 | HIGH | 5 | ya: SSH dan HTTP terbuka untuk seluruh internet |
| `m05-rawan` | AWS-0124 | LOW | tambahan | tidak langsung: aturan tanpa deskripsi hanya menyulitkan audit |
| `m05-rawan` | AWS-0131 | HIGH | tambahan | ya: disk root tidak terenkripsi |
| `m05-rawan` | AWS-0132 | HIGH | 6 | ya: bucket tanpa kunci KMS milik sendiri |
| `m05-aman` | AWS-0104 (`aws-ec2-no-public-egress-sgr`, `main.tf:147`) | CRITICAL | diterima (`trivy:ignore`) | egress HTTPS 443 ke `0.0.0.0/0` dibutuhkan skrip boot untuk memanggil API SSM dan KMS; VPC bawaan tanpa VPC endpoint dan endpoint berbayar per jam per AZ (K-05) |
| `m05-aman` | AWS-0089 (`aws-s3-enable-logging`, `main.tf:189-194`) | LOW | diterima (`trivy:ignore`) | bucket praktikum dibongkar tiap sesi; di sistem nyata log akses wajib untuk akuntabilitas |
| `m05-aman` | AWS-0090 (`aws-s3-enable-versioning`, `main.tf:189-194`) | MEDIUM | diterima (`trivy:ignore`) | bucket praktikum dibongkar tiap sesi; di sistem nyata versioning menjaga integritas laporan |

Temuan Tabel Audit yang **tidak** dilaporkan Trivy: nomor 1 (password di `default` variabel), 2 (password di `user_data`), 3 (output password tanpa `sensitive`), dan 4 (kebijakan role `Action = "*"`). Trivy hanya mencocokkan pola konfigurasi resource per baris kode; ia tidak menelusuri aliran nilai variabel ke template dan output, dan kebijakan IAM inline yang dibangun dengan `jsonencode` tidak diperiksa sebagai dokumen kebijakan. Hanya temuan 5 dan 6 yang tertangkap.

## Hasil Conftest

| Plan | Jumlah kegagalan | Alamat yang ditolak |
|---|---|---|
| `rawan.plan.json` | 6 (`6 tests, 0 passed, 0 warnings, 6 failures`) | `aws_iam_role_policy.api`, `aws_instance.api`, `aws_s3_bucket_policy.laporan`, `aws_vpc_security_group_ingress_rule.ssh`, `output.db_password`, `var.db_password` |
| `aman.plan.json` | 0 (`6 tests, 6 passed, 0 warnings, 0 failures`) | tidak ada |

Resource yang tercatat *known after apply* pada plan aman dan karena itu tidak terperiksa kebijakan: `aws_iam_role_policy.dekripsi`. Isi kebijakannya (`policy = (known after apply)`) merujuk ARN `aws_kms_key.m05` yang baru ada setelah apply, sehingga aturan 6 tidak punya dokumen untuk dibaca; seandainya kebijakan itu memakai `kms:*`, plan tetap lolos Conftest dan baru tertangkap verifier (`iam_minimal`) setelah apply. Kebijakan `baca_parameter` tetap terperiksa karena ARN parameter disusun dari `local.arn_parameter` yang sudah diketahui saat plan.

## Threat Model

| Butir | Isi untuk API laporan pada kasus kelompok Anda (sebut kode bukti A1–A6) |
|---|---|
| Aset | Laporan hasil lab, foto klinis, dan rujukan pasien yang diunduh lewat API laporan (A1: rahasia, termasuk data ter-pseudonim); password database RME dan kunci KMS yang melindunginya (A5); state OpenTofu yang memuat password tersebut |
| Aktor ancaman | Siapa pun di internet yang memegang tautan hasil lab (A6: satu tautan terbuka 11 hari di grup pasien); insider atau akun bekas karyawan yang masih aktif (A3, A6: 41 akun dokter); pihak ketiga dengan akses API atau VPN: 2 laboratorium mitra, 14 asuransi, vendor kios (A4); pemegang sesi `aws login` atau passphrase state |
| Jalur serangan | Mengunduh objek laporan lewat URL bucket tanpa autentikasi atau tautan tanpa kedaluwarsa; membaca password dari `user_data`, output, plan, atau state teks biasa; memakai kredensial role server yang disusupi untuk membaca resource lain; masuk lewat port admin yang terbuka; memakai akun yang tidak dicabut |
| Kontrol yang sudah ada | Pagar blok publik tingkat akun dan bucket, SSE-KMS dengan kunci sendiri (rotasi aktif), bucket policy menolak akses tanpa TLS (curl anonim `403`); password dibangkitkan `random_password`, disimpan `SecureString`, dirotasi lewat `putaran_rahasia` (versi 1 → 2); role server hanya `ssm:GetParameter` satu parameter dan `kms:Decrypt` lewat SSM; SG hanya HTTP dari /32 tanpa port admin; IMDSv2; state dan plan terenkripsi AES-GCM; Trivy dan Conftest sebelum apply |
| Risiko sisa | Egress 443 ke `0.0.0.0/0` diterima (AWS-0104), sehingga server yang disusupi masih dapat mengirim data keluar lewat HTTPS; logging akses dan versioning bucket tidak aktif (AWS-0089, AWS-0090), sehingga akses tidak tercatat untuk jejak audit yang diwajibkan kontrak asuransi (A2); kebijakan `dekripsi` tidak terperiksa Conftest sebelum apply; password juga ada di state dan di `/etc/koma/db.env` server; passphrase state di laptop dan pengelola password menjadi rahasia baru; verifier dengan `ec2:Describe*` masih dapat membaca `user_data`; akun bekas karyawan (A6) dan rotasi 12 kunci API laboratorium (A5) di luar stack ini |

## Langkah dan bukti

Satu baris per `koma cek m05`. Potret aktif terakhir sebelum destroy harus lulus semua cek kecuali `bersih_akhir`, dan potret terakhir sebelum mengumpulkan harus potret bersih.

| Potret | Langkah | Keadaan | Waktu (WIB) | Hasil penting (`Latihan lulus` / `Tugas lulus`, cek yang gagal, versi parameter) |
|---|---|---|---|---|
| 1 | D.6 | stack aman berjalan | 19-11 | tidak terambil: `verifier menolak (403): Forbidden` |
| 2 | E.2 | kosong | 19-11 | tidak terambil (`403`); bukti manual: `Destroy complete! Resources: 18 destroyed.`, `describe-instances` m05 running → `[]`, state tetap `encrypted_data`, kunci KMS `PendingDeletion` |
| 3 | Tugas Langkah 2 | dibangun ulang | 19-11 | tidak terambil (`403`); apply `18 added`, Conftest 0 failures, server `i-08a4d537823561768`, parameter versi 1 |
| 4 | Tugas Langkah 3 | setelah rotasi dan reboot | 19-11 | tidak terambil (`403`); parameter versi 2 (diubah 09:06:13 WIB), server yang sama di-reboot, `koma sehat` SEHAT 0,4 detik |
| 5 | Tugas Langkah 5 | kosong | 19-11 | tidak terambil (`403`); bukti manual: `Destroy complete! Resources: 18 destroyed.`; kunci KMS kedua (`60f338fa-…`) dijadwalkan dihapus |

Bukti tidak langsung yang hanya dapat diambil selama stack hidup:

| Bukti | Potret 1 | Potret 4 |
|---|---|---|
| Baris `KOMA-PENANDA` | `rahasia dimuat: 600 root dari /koma/123450039/m05/db-password` | dua baris `rahasia dimuat: 600 root dari /koma/123450039/m05/db-password` (boot pertama dan setelah reboot) |
| Kunci tingkat atas `m05/aman.tfstate` | `encrypted_data, encryption_version, lineage, meta, serial` | sama (state tetap terenkripsi) |
| `describe-parameters` (tipe, versi) | `SecureString`, kunci m05, versi 1 | `SecureString`, versi 2 |
| `get-bucket-policy-status` | `IsPublic: false` | `IsPublic: false` (konfigurasi bucket tidak berubah) |
| `curl` anonim ke objek laporan | `403` | `403` (konfigurasi bucket tidak berubah) |

# Latihan 5.1 — Satu pagar, satu perbaikan

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | k01 Klinik Sehat Lampung |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m05.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 05**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan passphrase, isi `rawan.plan.json` atau `aman.plan.json`, atau 12 digit ID akun (tulis `<akun>`).

## 1. Pagar di dua plan

Keluaran `conftest test rawan.plan.json --policy ../../policy` (enam kegagalan):

```text
FAIL - rawan.plan.json - main - aws_iam_role_policy.api: kebijakan IAM mengizinkan aksi *
FAIL - rawan.plan.json - main - aws_instance.api: user_data memuat nilai rahasia tertulis langsung
FAIL - rawan.plan.json - main - aws_s3_bucket_policy.laporan: bucket policy mengizinkan akses publik (Principal *)
FAIL - rawan.plan.json - main - aws_vpc_security_group_ingress_rule.ssh: port admin atau semua protokol terbuka untuk internet
FAIL - rawan.plan.json - main - output.db_password: output rahasia tidak ditandai sensitive
FAIL - rawan.plan.json - main - var.db_password: variabel rahasia punya nilai bawaan

6 tests, 0 passed, 0 warnings, 6 failures, 0 exceptions
```

Keluaran `conftest test aman.plan.json --policy ../../policy`:

```text
6 tests, 6 passed, 0 warnings, 0 failures, 0 exceptions
```

## 2. Dua masukan untuk aturan 2

Isi `sg-gagal.json` (seharusnya ditolak):

```json
{"resource_changes": [{"address": "aws_vpc_security_group_ingress_rule.semua_ipv6", "type": "aws_vpc_security_group_ingress_rule",
  "change": {"after": {"cidr_ipv4": null, "cidr_ipv6": "::/0", "ip_protocol": "tcp", "from_port": 0, "to_port": 65535}}}]}
```

Isi `sg-lolos.json` (seharusnya lolos):

```json
{"resource_changes": [{"address": "aws_vpc_security_group_ingress_rule.https_publik", "type": "aws_vpc_security_group_ingress_rule",
  "change": {"after": {"cidr_ipv4": "0.0.0.0/0", "cidr_ipv6": null, "ip_protocol": "tcp", "from_port": 443, "to_port": 443}}}]}
```

Keluaran `conftest test sg-gagal.json sg-lolos.json --policy ../koma-infra/policy`:

```text
FAIL - sg-gagal.json - main - aws_vpc_security_group_ingress_rule.semua_ipv6: port admin atau semua protokol terbuka untuk internet

12 tests, 11 passed, 0 warnings, 1 failure, 0 exceptions
```

Contoh mana yang tidak ada di stack rawan, dan mengapa Anda memilihnya: keduanya. `sg-gagal.json` membuka semua port tcp 0–65535 dari IPv6 `::/0`; aturan ini tidak menyebut angka 22 dan tidak memakai IPv4, tetapi tetap membuka SSH dan RDP ke seluruh internet. Saya memilihnya karena aturan yang hanya memeriksa `cidr_ipv4 == "0.0.0.0/0"` dan `from_port == 22` akan meloloskannya. `sg-lolos.json` membuka HTTPS 443 dari `0.0.0.0/0` untuk membuktikan bahwa aturan 2 tidak menolak semua sumber internet, hanya gabungan sumber internet dengan port admin atau semua protokol.

Baris kondisi Rego yang menyala pada `sg-gagal.json`, dan baris yang tidak terpenuhi pada `sg-lolos.json`: pada `sg-gagal.json`, `sumber_internet(a)` terpenuhi lewat definisi kedua `a.cidr_ipv6 == "::/0"` (definisi pertama gagal karena `cidr_ipv4` bernilai `null`), dan `port_berbahaya(a)` terpenuhi lewat definisi rentang: untuk `p = 22` berlaku `a.from_port <= p` (0 ≤ 22) dan `p <= a.to_port` (22 ≤ 65535). Keduanya benar sehingga `deny` menyala. Pada `sg-lolos.json`, `sumber_internet(a)` terpenuhi (`0.0.0.0/0`), tetapi `port_berbahaya(a)` tidak: `ip_protocol` bernilai `"tcp"` bukan `"-1"`, dan baik 22 maupun 3389 tidak berada di rentang 443–443. Satu kondisi yang gagal membuat seluruh badan aturan gagal, sehingga tidak ada `FAIL`.

Apakah aturan Anda sempat salah memutuskan? Bila ya, apa yang Anda ubah: ya, pada aturan 6 (bukan aturan 2). Saat menguji dengan masukan buatan, kebijakan IAM yang `Statement`-nya ditulis sebagai satu objek (bukan daftar) dan berisi `ec2:*` tidak ditolak, karena fungsi `daftar(x)` hanya menangani string dan daftar. Saya menambahkan definisi `daftar(x) := [x] if is_object(x)`, lalu menjalankan ulang Checkpoint B: tetap enam kegagalan pada `rawan.plan.json`. Aturan 2 langsung memakai perbandingan rentang `from_port <= p <= to_port` dan memeriksa `cidr_ipv6`, sehingga contoh IPv6 dan rentang port tertangkap sejak awal.

Apakah plan yang lolos Conftest pasti aman? Jawab dengan satu contoh dari D.3.2 (`after_unknown`): tidak. Di plan aman, `aws_iam_role_policy.dekripsi` tercatat `policy = (known after apply)` karena merujuk ARN kunci KMS yang baru ada setelah apply, sehingga aturan 6 tidak punya dokumen untuk diperiksa. Seandainya kebijakan itu memakai `kms:*`, plan tetap lolos Conftest dan baru tertangkap verifier (`iam_minimal`) setelah apply. Conftest juga hanya menolak pola yang ditulis: password mentah yang disimpan sebagai nilai tag tidak cocok dengan `pola_nilai_rahasia` dan akan lolos.

## 3. Bukti tidak langsung (D.5, D.6)

| Bukti | Hasil ringkas |
|---|---|
| `get-bucket-policy-status` (`IsPublic`) | `false` |
| `get-bucket-encryption` (algoritme, kunci) | `aws:kms`, `arn:aws:kms:ap-southeast-2:<akun>:key/3f5c6c74-…`, `BucketKeyEnabled: true` (SSE-C diblokir) |
| `describe-parameters` (tipe, kunci, versi; tanpa nilai) | `/koma/123450039/m05/db-password`, `SecureString`, ARN kunci yang sama (`key/3f5c6c74-…`), versi 1 |
| Kunci tingkat atas `m05/aman.tfstate` | `['encrypted_data', 'encryption_version', 'lineage', 'meta', 'serial']` |
| Baris `KOMA-PENANDA` | `KOMA-PENANDA rahasia dimuat: 600 root dari /koma/123450039/m05/db-password` |
| `curl` anonim ke objek laporan (kode HTTP) | `403` |
| `koma sehat` | `SEHAT setelah 0.4 detik: {'status': 'ok'}` |

## 4. Bukti

- Potret 1 (D.6) pada (WIB), `Latihan lulus`: 19-11, tidak terambil: `koma cek m05` → `verifier menolak (403): Forbidden` (sama seperti Modul 03 dan 04; potret dilewati atas arahan dosen)
- Potret 2 (E.2, bersih) pada (WIB), `bersih_akhir`:
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m05.json` yang diunggah:
- Berkas `*.tfplan` dan `*.plan.json` sudah dihapus (E.3): ya / belum

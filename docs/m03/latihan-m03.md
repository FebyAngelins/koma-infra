# Latihan 3.1 — Membuktikan yang tertutup

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | k01 Klinik Sehat Lampung |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m03.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 03**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri.

## 1. Dua aturan yang sengaja salah

Salin isi `stacks/m03-app/latihan-salah.tf` yang Anda tulis, termasuk aturan kedua yang Anda susun dari Tabel 3.12a.

```hcl
# LATIHAN 3.1: aturan yang SENGAJA salah. Hapus berkas ini setelah dibuktikan.

# Salah 1: db dibuka untuk SG alb (seharusnya db hanya dari web)
resource "aws_vpc_security_group_ingress_rule" "salah_db_dari_alb" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Salah 2: web dibuka untuk seluruh internet (seharusnya web hanya dari SG alb)
resource "aws_vpc_security_group_ingress_rule" "salah_web_dari_internet" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
```

Baris ringkasan `tofu plan` saat aturan ditambahkan, dan apakah ada server yang ikut diganti:

```text
Plan: 2 to add, 0 to change, 0 to destroy.
```

Hanya dua `aws_vpc_security_group_ingress_rule` yang ditambahkan (`sgr-0434b0a7b6fcceeed` dan `sgr-0954ac68bff2021da`); tidak ada server yang diganti. Aturan security group dapat diubah selagi server berjalan, berbeda dengan `user_data` di Modul 02 yang memaksa server baru. Setelah apply, `tofu plan` menyatakan `No changes` dengan kedua aturan salah ikut tercantum di state.

## 2. Apa kata verifier

Salin baris `matriks_negatif` (dan `matriks_positif`) dari potret 3:

```text
koma cek m03 - Jaringan sebagai Kode (verifier dosen)
NIM 123450039, kelompok k01, region ap-southeast-2
koma: verifier menolak (403): Forbidden
```

Potret 3 tidak dapat diambil: verifier menolak di Function URL (`403 AccessDeniedException`, RequestId `e6cf860b-671b-4dba-94e9-9ffd260e34c4`), padahal NIM/kelompok, role `koma-verifier-ro`, dan ExternalId sudah diperiksa benar. Atas arahan dosen (13 Nov 2026) potret dilewati. Pembacaan di bawah adalah apa yang semestinya dilaporkan verifier berdasarkan aturan yang terpasang.

Pembacaan saya, bagian demi bagian (jalur mana yang terbuka, aturan mana penyebabnya, prinsip mana yang dilanggar):

- `terbuka: internet->web:80`: aturan `salah_web_dari_internet` membuka port 80 SG web untuk `0.0.0.0/0`; melanggar prinsip "web hanya dari alb".
- `terbuka: alb->db:5432`: aturan `salah_db_dari_alb` membuat SG db menerima 5432 dari SG alb; melanggar prinsip "db hanya dari web".
- `0.0.0.0/0 di koma-123450039-m03-web`: SG web menerima seluruh internet, jalur negatif "internet → web" di matriks kini diizinkan oleh aturan walaupun belum ada paket yang bisa sampai.

Mengapa `matriks_positif` tetap LULUS, dan mengapa `Latihan lulus` tetap `True`: aturan yang terlalu longgar tidak menutup jalur yang memang diperlukan, jadi alb → web:80 dan web → db:5432 tetap diizinkan; justru karena itu bukti positif saja tidak cukup dan perlu bukti negatif. `Latihan lulus` tetap `True` karena `matriks_negatif` hanya syarat Tugas; yang terdampak adalah `Tugas lulus`.

## 3. Uji dari laptop selagi aturan salah terpasang

| No. | Jalur | Perintah yang saya jalankan | Harapan | Hasil (salin baris keluaran) |
|---|---|---|---|---|
| 1 | laptop → ALB:80 | `curl -s --max-time 5 http://koma-123450039-m03-801830194.ap-southeast-2.elb.amazonaws.com/versi` | BUKA | `{"versi": "3.0.0", "peran": "web", "host": "ip-10-30-10-219.ap-southeast-2.compute.internal"}` |
| 2 | laptop → web-1:80 langsung | `curl --max-time 5 http://10.30.10.219/health` | tidak sampai | `curl: (28) Connection timed out after 5004 milliseconds` |
| 3 | laptop → ALB:8080 | `curl --max-time 5 http://koma-123450039-m03-801830194.ap-southeast-2.elb.amazonaws.com:8080/` | tidak sampai | `curl: (28) Connection timed out after 5006 milliseconds` |
| 4 | jaringan lain → ALB:80 (opsional) | tidak dijalankan | tidak sampai | tidak dijalankan (opsional) |

## 4. Mengapa tetap salah walaupun tidak ada paket yang lolos

Uji 2 gagal walaupun security group web menerima `0.0.0.0/0`. Lapis apa saja yang masih menutup jalan itu, dan perubahan apa di masa depan yang akan membuat aturan itu langsung berbahaya?

Yang masih menutup ada tiga lapis: server web tidak punya IP publik, alamat `10.30.10.219` tidak dapat dirutekan di internet sehingga paket dari laptop tidak pernah sampai ke AWS, dan route table subnet privat tidak punya rute `0.0.0.0/0` sehingga tidak ada jalan pulang. Aturan itu menjadi langsung berbahaya begitu salah satu lapis berubah, misalnya server web dipindah ke subnet publik dengan IP publik untuk "debug sebentar", atau NAT dan rute ditambahkan untuk worker; saat itu port 80 web terbuka ke seluruh internet tanpa melewati ALB, tanpa batas `/32`, dan tanpa health check.

Untuk aturan db dari alb: apa yang kelak memakai security group alb, dan mengapa "db hanya dari web" lebih sempit daripada "db dari tier yang kita percaya"?

SG alb kelak dipakai oleh ALB lain (mis. ALB untuk API lab mitra dan asuransi, atau ALB internal) dan apa pun yang ditempeli SG itu. Aturan `db dari alb` berarti setiap anggota SG alb, termasuk yang ditambahkan orang lain kemudian, langsung bisa membuka port 5432 basis data RME. "db hanya dari web" lebih sempit karena hanya satu tier yang memang menjalankan kueri yang boleh bicara ke db; "dari tier yang kita percaya" bergantung pada daftar kepercayaan yang mudah membengkak dan tidak tercatat di matriks.

Kaitkan dengan ancaman A3 kasus kelompok Anda dan gagasan *defense in depth*: A3 Klinik Sehat Lampung menyebut ransomware dari PC klinik di segmen flat, dan pemicu M03 adalah server vendor kios di segmen yang sama dapat membuka port database RME (A3, A4, E7). Dua aturan salah ini mengembalikan pola itu ke cloud: tier yang tidak perlu (alb, atau internet) mendapat jalan ke db atau web. *Defense in depth* berarti setiap lapis harus benar sendiri; hari ini tidak ada paket yang lolos hanya karena lapis IP privat dan route table masih utuh, bukan karena SG-nya benar. Bila satu lapis itu berubah, SG yang longgar tidak lagi menahan apa pun, jadi verifier tetap menggagalkannya walaupun uji dari laptop tidak menembus.

## 5. Bukti

- Potret 3 (aturan salah terpasang) pada (WIB): tidak terambil, `koma cek m03` → `verifier menolak (403): Forbidden` (13 Nov 2026), dilewati atas arahan dosen
- Potret 4 (aturan salah dihapus) pada (WIB), `matriks_negatif`: tidak terambil, `403 Forbidden` (13 Nov 2026), dilewati atas arahan dosen
- `tofu plan` setelah berkas dihapus (`No changes`?): `No changes. Your infrastructure matches the configuration.`
- `stacks/m03-app/latihan-salah.tf` sudah tidak ada dan tidak ter-commit: ya
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m03.json` setelah Bagian E:

# Latihan 2.1 — Goreng atau panggang

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m02.json` ke **Latihan Mandiri di Lab — Modul 02**. Angka berasal dari akun dan terminal Anda sendiri.

## 1. Kode server goreng

Salin `aws_instance.goreng` dan output `url_goreng` yang Anda tulis.

```hcl
# Latihan 2.1: server "goreng" (AMI publik + cloud-init saat boot) sebagai pembanding waktu siap
resource "aws_instance" "goreng" {
  count = var.bandingkan_goreng ? 1 : 0

  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]
  user_data                   = local.cloud_init
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name  = "${local.awalan}-goreng"
    peran = "goreng"
    versi = var.versi
  }
}

output "url_goreng" {
  value = var.bandingkan_goreng ? "http://${aws_instance.goreng[0].public_ip}" : null
}
```

`tofu plan` dengan `bandingkan_goreng = false` (salin baris ringkasannya):

```text
No changes. Your infrastructure matches the configuration.
```

## 2. Pengukuran

Waktu siap diukur dengan `koma sehat` yang dijalankan segera setelah apply selesai.

| Server | Sumber AMI | "Creation complete" | `koma sehat` (detik) | Total sampai sehat | Jawaban `/versi` |
|---|---|---|---|---|---|
| api 2.0.0 (C.4) | AMI milik sendiri (`ami-04c8c952bb796d41d`) | 18 dtk | tidak tercatat | tidak tercatat | `2.0.0` |
| api 2.1.0 (D.3) | AMI milik sendiri (`ami-0808a03b2cea594d9`) | tidak tercatat | tidak tercatat | tidak tercatat | `2.1.0` |
| goreng 2.1.0 (Latihan) | AMI publik `ami-062900c135ab91582` + user data | tidak tercatat | tidak tercatat | tidak tercatat | `2.1.0` |

Selisih rata-rata waktu siap server goreng dibanding server api: ... detik. Dugaan pre-lab saya: ... detik.

## 3. Mengapa selisihnya sebesar itu

Kedua server sama-sama menunggu firmware, kernel, dan systemd. Server api lahir dari AMI yang sudah berisi `/opt/koma/koma_api.py`, `koma.env`, dan unit `koma-api.service` yang sudah di-`enable`, sehingga systemd langsung menyalakan layanan pada boot. Server goreng lahir dari AMI publik kosong: cloud-init harus membaca user data dari IMDS, menulis tiga berkas lewat `write_files`, lalu baru di tahap `runcmd` menjalankan `daemon-reload` dan `enable --now`, sehingga `/health` baru menjawab setelah cloud-init hampir selesai. Selisihnya tidak terlalu besar karena template praktikum hanya menulis berkas, tidak mengunduh apa pun.

Bila template harus menjalankan `dnf install` atau mengunduh dependensi, selisihnya membengkak menjadi menit dan bergantung pada kecepatan repositori. Lebih parah lagi, security group stack ini tidak punya aturan keluar sama sekali (`keluar: []` di C.4.4), sehingga server goreng tidak akan bisa mengunduh paket dan menyala tanpa API. Server dari AMI tidak terpengaruh karena semua yang dibutuhkan sudah ada sebelum ia lahir.

## 4. Kapan fry masih masuk akal

Untuk Klinik Sehat Lampung, aplikasi API RME dan seluruh dependensinya harus dipanggang: rencana 24 server API RME dan 70 server cache di klinik (C3) berarti puluhan kali menunggu pemasangan dan puluhan kesempatan gagal, sementara Divisi TI hanya 14 orang dan belum terbiasa IaC (E6), dan klinik terhubung lewat VPN broadband 20–50 Mbps yang tidak stabil (E2), sehingga server di klinik tidak boleh bergantung pada unduhan saat boot. Yang masuk akal tetap digoreng adalah nilai khusus lingkungan atau lokasi, misalnya alamat database dev/staging/prod (G2) atau kode klinik, yang cukup diberikan lewat user data kecil. Ini gabungan yang disarankan Morris (2025, hlm. 198): panggang sebanyak mungkin, goreng hanya yang khusus lingkungan.

## 5. Bukti

- Potret 3 (server goreng hidup) pada (WIB): 06-11-2026 15:14:40 (`2026-11-06T08:14:40Z`), server goreng `i-0c4efe4e8b13ffd91` di `http://15.135.214.5`
- `grep -c "m02-goreng" bukti/bukti-m02.json` menghasilkan: 1
- `bandingkan_goreng` dikembalikan ke `false` dan server goreng terhapus: ya (`1 destroyed`, plan sesudahnya `No changes`)
- `latihan_lulus` pada `bukti/bukti-m02.json` setelah Bagian E: `true` (potret 4 kosong)

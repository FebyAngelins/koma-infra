# Latihan 1.1 — Memilih dari katalog, bukan mengetik angka

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | Klinik Sehat Lampung |

Berkas ini ditulis sendiri. Keluaran plan berasal dari akun AWS Anda; penjelasannya dengan kata-kata Anda
sendiri. Simpan di folder mata kuliah, di luar repo `koma-infra`, lalu unggah bersama
`bukti/bukti-m01.json` (setelah E.1, potret terakhir kosong) ke tugas **Latihan Mandiri di Lab — Modul 01**.

## L.1 — `api` naik ke ukuran `sedang`

Blok plan yang memuat baris berubah:

```text
  # aws_instance.layanan["api"] will be updated in-place
  ~ resource "aws_instance" "layanan" {
        id                                   = "i-0241a7743e310aecd"
      ~ instance_type                        = "t3.micro" -> "t3.small"
      ~ tags                                 = {
            "Name"   = "koma-123450039-m01-api"
            "peran"  = "api"
          ~ "ukuran" = "kecil" -> "sedang"
        }
      ~ tags_all                             = {
          ~ "ukuran"     = "kecil" -> "sedang"
            # (8 unchanged elements hidden)
        }
        # (27 unchanged attributes hidden)

        # (9 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Simbolnya `~` (update in-place) karena API EC2 mengizinkan `instance_type` diubah pada instance yang
sama, sehingga ID `i-0241a7743e310aecd` tetap dan disk serta IP privatnya ikut dipertahankan. Namun
provider mengerjakannya dengan menghentikan (stop) instance, mengganti tipenya, lalu menyalakannya
lagi. Artinya server `api` tetap "sama" tetapi sempat mati beberapa puluh detik sampai beberapa menit;
selama itu permintaan pengguna ke `api` gagal, jadi `~` tidak berarti tanpa gangguan.

## L.2 — `web` pindah ke Debian 12 (tidak di-apply)

Blok plan dengan `must be replaced` dan `# forces replacement`, beserta baris ringkasannya:

```text
  # aws_instance.layanan["web"] must be replaced
-/+ resource "aws_instance" "layanan" {
      ~ ami                = "ami-062900c135ab91582" -> "ami-0c8ee5714a9238c0f" # forces replacement
      ~ id                 = "i-09379a18a1728d275" -> (known after apply)
      ~ availability_zone  = "ap-southeast-2c" -> (known after apply)
      ~ private_ip         = "172.31.16.240" -> (known after apply)
      ~ private_dns        = "ip-172-31-16-240.ap-southeast-2.compute.internal" -> (known after apply)
      ~ subnet_id          = "subnet-0ebbf18b968dfc10e" -> (known after apply)
        tags               = {
            "Name"   = "koma-123450039-m01-web"
            "peran"  = "web"
            "ukuran" = "kecil"
        }
      ~ root_block_device {
          ~ volume_id = "vol-0f400758f09b76da8" -> (known after apply)
            # (atribut lain dipangkas)
        }
        # (atribut dan sub-blok lain dipangkas)
    }

Plan: 1 to add, 1 to change, 1 to destroy.
```

Simbolnya `-/+` (destroy lalu create). Atribut pemicunya `ami` yang ditandai `# forces replacement`:
sistem operasi dipasang dari AMI saat instance lahir, jadi AMI lain tidak bisa diterapkan pada instance
yang sama. Bersama instance lama ikut hilang ID `i-09379a18a1728d275`, IP privat 172.31.16.240,
nama DNS privat, AZ, dan disk akar `vol-0f400758f09b76da8` beserta seluruh isinya. Bagi pengguna,
`web` mati sejak instance lama dihapus sampai instance baru siap, lalu muncul di alamat IP berbeda
dan tanpa data yang sebelumnya tersimpan di disk. Ringkasannya memuat `1 to change` dan
`1 to destroy` sekaligus karena satu plan menggabungkan dua perubahan: `api` diubah di tempat (L.1),
sedangkan `web` dihapus lalu dibuat ulang (dihitung sebagai 1 destroy dan 1 add).

## L.3 — Ukuran di luar katalog

Pesan galat `tofu plan` dengan ukuran `raksasa`:

```text
Planning failed. OpenTofu encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on variables.tf line 26:
│   26: variable "layanan" {
│     ├────────────────
│     │ var.layanan is map of object with 2 elements
│ 
│ Ukuran hanya boleh kecil (t3.micro) atau sedang (t3.small).
│ 
│ This was checked by the validation rule at variables.tf:44,3-13.
╵
```

Kapan galat ini muncul (sebelum atau sesudah menghubungi AWS) dan mengapa itu penting:

Galat muncul saat OpenTofu menyusun plan, sebelum ada permintaan apa pun untuk membuat atau
mengubah instance. Keluaran memang menunjukkan dua data source AMI sempat dibaca (itu hanya
permintaan baca), tetapi tidak ada refresh instance, tidak ada plan, dan tidak ada instance yang
disentuh. Ini penting karena nilai yang salah ketik atau terlalu mahal (misalnya tipe besar) ditolak di
laptop dengan pesan yang jelas, bukan gagal di tengah apply, menghabiskan kredit, atau baru ketahuan
setelah server dibuat. Katalog `kecil`/`sedang` memaksa semua orang memilih dari daftar yang sudah
disetujui.

## L.4 — Bukti

- Waktu `koma cek m01` (WIB):
- Nomor potret:
- `Latihan lulus` di keluaran `koma cek`:
- Tipe instance `api` setelah apply (dari `tofu output instance`): `t3.small`, ID tetap `i-0241a7743e310aecd`, IP privat tetap 172.31.30.170; `Modifications complete after 38s` (lama `api` dihentikan dan dinyalakan ulang)
- Plan sesudah apply berakhir `exit code = 0` (`No changes. Your infrastructure matches the configuration.`)

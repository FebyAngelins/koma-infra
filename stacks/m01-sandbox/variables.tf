variable "nim" {
  type        = string
  description = "NIM praktikan; dipakai di tag dan nama resource"
  validation {
    condition     = can(regex("^[0-9]{8,10}$", var.nim))
    error_message = "NIM harus 8-10 digit angka."
  }
}

variable "kelompok" {
  type        = string
  description = "ID kelompok kasus (k01-k05; k00 contoh dosen)"
  validation {
    condition     = can(regex("^k0[0-5]$", var.kelompok))
    error_message = "Kelompok harus k01-k05 (k00 untuk contoh dosen)."
  }
}

variable "region" {
  type        = string
  default     = "ap-southeast-2"
  description = "Region proyek AWS (Indonesia: ap-southeast-2)"
}

# Bagian C: katalog server sandbox (kunci = nama pendek komponen)
variable "layanan" {
  description = "Katalog server sandbox: kunci = nama pendek, nilai = peran, ukuran preset, dan OS"
  type = map(object({
    peran  = string
    ukuran = string
    os     = optional(string, "al2023")
  }))
  # Katalog kasus k01 Klinik Sehat Lampung (E1): tiga komponen aplikasi
  default = {
    portal       = { peran = "web", ukuran = "kecil" }    # portal pasien dan dasbor klinik
    rme-api      = { peran = "api", ukuran = "sedang" }   # API pendaftaran dan RME (E4 99,95%, E5 p95 < 500 ms)
    notif-worker = { peran = "worker", ukuran = "kecil" } # pengirim hasil lab dan notifikasi pasien
  }

  # kunci dipakai di tag Name, jadi polanya mengikuti cek nama_konvensi
  validation {
    condition     = alltrue([for k in keys(var.layanan) : can(regex("^[a-z0-9-]+$", k))])
    error_message = "Kunci layanan: huruf kecil, angka, dan tanda hubung saja."
  }
  # ukuran dipilih dari katalog preset, bukan tipe instance bebas
  validation {
    condition     = alltrue([for l in values(var.layanan) : contains(["kecil", "sedang"], l.ukuran)])
    error_message = "Ukuran hanya boleh kecil (t3.micro) atau sedang (t3.small)."
  }
  # peran dibatasi pada komponen yang dikenal
  validation {
    condition     = alltrue([for l in values(var.layanan) : contains(["web", "api", "worker", "db"], l.peran)])
    error_message = "Peran hanya boleh web, api, worker, atau db."
  }
  # OS dibatasi pada image yang punya data source
  validation {
    condition     = alltrue([for l in values(var.layanan) : contains(["al2023", "debian12"], l.os)])
    error_message = "OS hanya boleh al2023 atau debian12."
  }
}

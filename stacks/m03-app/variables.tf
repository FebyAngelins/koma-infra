variable "nim" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{8,10}$", var.nim))
    error_message = "NIM harus 8-10 digit angka."
  }
}

variable "kelompok" {
  type = string
  validation {
    condition     = can(regex("^k0[0-5]$", var.kelompok))
    error_message = "Kelompok harus k01-k05 (k00 untuk contoh dosen)."
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "cidr_saya" {
  type        = string
  description = "IP publik komputer praktikan sebagai /32 (keluaran `koma ip`)"
  validation {
    condition     = can(cidrhost(var.cidr_saya, 0)) && endswith(var.cidr_saya, "/32")
    error_message = "Isi dengan satu alamat IPv4 berakhiran /32, mis. 36.70.1.2/32."
  }
}

variable "jumlah_web" {
  type        = number
  default     = 2
  description = "Jumlah server web di belakang load balancer (1 bila kuota vCPU akun kecil)"
  validation {
    condition     = var.jumlah_web >= 1 && var.jumlah_web <= 2
    error_message = "Jumlah server web 1 atau 2."
  }
}

variable "versi" {
  type    = string
  default = "3.0.0"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi))
    error_message = "Versi berbentuk MAYOR.MINOR.PATCH."
  }
}

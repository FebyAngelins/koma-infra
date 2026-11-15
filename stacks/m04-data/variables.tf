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

variable "versi" {
  type        = string
  default     = "4.0.0"
  description = "Versi server db; versi baru mengganti server, bukan datanya"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi))
    error_message = "Versi berbentuk MAYOR.MINOR.PATCH."
  }
}

variable "ukuran_data_gib" {
  type        = number
  default     = 1
  description = "Ukuran volume data (GiB)"
  validation {
    condition     = var.ukuran_data_gib >= 1 && var.ukuran_data_gib <= 4
    error_message = "Volume data praktikum 1-4 GiB."
  }
}

variable "retensi_versi_hari" {
  type        = number
  default     = 30
  description = "Berapa hari versi lama objek arsip disimpan"
  validation {
    condition     = var.retensi_versi_hari >= 1 && var.retensi_versi_hari <= 365
    error_message = "Retensi versi 1-365 hari."
  }
}

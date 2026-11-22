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

variable "cost_center" {
  type = string
  validation {
    condition     = can(regex("^CC-[0-9]{3}$", var.cost_center))
    error_message = "cost_center berbentuk CC-123 (G4)."
  }
}

variable "data_class" {
  type = string
  validation {
    condition     = contains(["publik", "internal", "rahasia"], var.data_class)
    error_message = "data_class hanya publik, internal, atau rahasia."
  }
}

# ---------------------------------------------------------------- versi dan rilis bertahap

variable "versi_stabil" {
  type        = string
  description = "Tag image yang dilayani layanan stabil (harus sudah ada di registri)"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi_stabil))
    error_message = "Versi berbentuk MAYOR.MINOR.PATCH."
  }
}

variable "versi_canary" {
  type        = string
  default     = ""
  description = "Tag image canary; kosong = tanpa canary"
  validation {
    condition     = var.versi_canary == "" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.versi_canary))
    error_message = "Versi canary kosong atau berbentuk MAYOR.MINOR.PATCH."
  }
}

variable "bobot_canary" {
  type        = number
  default     = 0
  description = "Persen permintaan yang diteruskan ke canary (0-100)"
  validation {
    condition     = var.bobot_canary >= 0 && var.bobot_canary <= 100 && floor(var.bobot_canary) == var.bobot_canary
    error_message = "bobot_canary bilangan bulat 0-100."
  }
  validation {
    condition     = var.bobot_canary == 0 || var.versi_canary != ""
    error_message = "Bobot canary > 0 membutuhkan versi_canary."
  }
}

# ---------------------------------------------------------------- kapasitas

variable "ukuran" {
  type        = string
  default     = "kecil"
  description = "Preset task Fargate: kecil (0,25 vCPU, 512 MB) atau sedang (0,5 vCPU, 1 GB)"
  validation {
    condition     = contains(["kecil", "sedang"], var.ukuran)
    error_message = "Ukuran hanya boleh kecil atau sedang."
  }
}

variable "skala_maks" {
  type        = number
  default     = 3
  description = "Jumlah task stabil maksimum saat auto scaling (C3, C5)"
  validation {
    condition     = var.skala_maks >= 1 && var.skala_maks <= 3
    error_message = "skala_maks 1-3 (kuota dan kredit akun Free plan)."
  }
}

variable "target_cpu" {
  type        = number
  default     = 50
  description = "Rata-rata CPU (%) yang dijaga target tracking"
  validation {
    condition     = var.target_cpu >= 20 && var.target_cpu <= 90
    error_message = "target_cpu 20-90 persen."
  }
}

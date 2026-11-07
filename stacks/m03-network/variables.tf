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

variable "cidr_vpc" {
  type        = string
  default     = "10.30.0.0/16"
  description = "Blok alamat VPC; satu /16 di dalam 10.0.0.0/8"
  validation {
    condition     = can(cidrhost(var.cidr_vpc, 0)) && endswith(var.cidr_vpc, "/16") && startswith(var.cidr_vpc, "10.")
    error_message = "CIDR VPC harus satu /16 di dalam 10.0.0.0/8, mis. 10.30.0.0/16."
  }
}

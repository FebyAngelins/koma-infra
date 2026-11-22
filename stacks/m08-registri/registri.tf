# Registri image Modul 08 (dijalankan dari laptop). Registri TIDAK ikut dibongkar saat layanan
# dibangun ulang dari nol: image adalah artefak hasil build, bukan infrastruktur yang dibangun
# ulang. Dibongkar di akhir praktikum (Tugas, langkah terakhir).
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {}
}

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

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m08"
      stack        = "m08-registri"
      "managed-by" = "opentofu"
    }
  }
}

# TODO A.1  aws_ecr_repository.api ("koma-${var.nim}-m08-api", IMMUTABLE, force_delete, scan_on_push,
#           tag peran = "registri") dan aws_ecr_lifecycle_policy.api (simpan 5 image terbaru)
# TODO A.1  output repo_url

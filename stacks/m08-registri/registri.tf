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

# A.1 Tag image tidak dapat ditimpa: versi 8.0.0 selalu berarti isi yang sama, sehingga task
# definition yang menyebut 8.0.0 dapat diulang persis (reproducible).
resource "aws_ecr_repository" "api" {
  name                 = "koma-${var.nim}-m08-api"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true # repo lab: image ikut terhapus saat destroy

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "koma-${var.nim}-m08-api", peran = "registri" }
}

# Simpan lima image terakhir saja: ruang ECR ditagih per GB-bulan.
resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "simpan 5 image terbaru"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 5 }
      action       = { type = "expire" }
    }]
  })
}

output "repo_url" {
  value = aws_ecr_repository.api.repository_url
}

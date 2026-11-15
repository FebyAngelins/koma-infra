# Bucket state OpenTofu (Modul 04, dijalankan SEKALI dan TIDAK di-destroy selama kursus).
# Stack ini sendiri memakai state lokal: bucket harus ada sebelum stack lain bisa menyimpan
# state di dalamnya.
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
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
      modul        = "m00"
      stack        = "m00-state"
      "managed-by" = "opentofu"
    }
  }
}

data "aws_caller_identity" "saya" {}

resource "aws_s3_bucket" "state" {
  # Nama bucket S3 berlaku global; ID akun membuatnya unik.
  bucket = "koma-${var.nim}-tfstate-${data.aws_caller_identity.saya.account_id}"
  tags   = { Name = "koma-${var.nim}-tfstate", peran = "state" }
}

# Setiap apply menyimpan versi state baru; versi lama bisa dipulihkan bila state rusak.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State memuat ID, alamat, dan kadang rahasia: tidak boleh pernah publik.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket     = aws_s3_bucket.state.id
  depends_on = [aws_s3_bucket_versioning.state]
  rule {
    id     = "versi-lama-90-hari"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

output "bucket" {
  value = aws_s3_bucket.state.id
}

# Isi siap pakai untuk stacks/m04-data/backend.hcl.
output "backend_hcl_m04" {
  value = <<-EOT
    bucket       = "${aws_s3_bucket.state.id}"
    key          = "m04/data.tfstate"
    region       = "${var.region}"
    encrypt      = true
    use_lockfile = true
  EOT
}

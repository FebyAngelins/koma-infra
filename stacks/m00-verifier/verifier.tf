# Role baca-saja untuk verifier dosen (Modul 03, dijalankan SEKALI dan TIDAK di-destroy
# selama kursus). Verifier Lambda di akun dosen meminjam role ini untuk memeriksa akun Anda;
# ExternalId mengikat role ke NIM Anda sehingga verifier tidak bisa dipakai memeriksa akun
# orang lain atas nama Anda.
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

variable "verifier_role_arn" {
  type        = string
  description = "ARN role eksekusi verifier Lambda milik dosen (diumumkan di kelas)"
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/koma-verifier-lambda$", var.verifier_role_arn))
    error_message = "Isi ARN role verifier dari dosen, mis. arn:aws:iam::123456789012:role/koma-verifier-lambda."
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m00"
      stack        = "m00-verifier"
      "managed-by" = "opentofu"
    }
  }
}

resource "aws_iam_role" "verifier" {
  name        = "koma-verifier-ro"
  description = "Dipinjam verifier praktikum Komputasi Awan; hanya membaca metadata"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.verifier_role_arn }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "sts:ExternalId" = "koma-${var.nim}" } }
    }]
  })
  max_session_duration = 3600
}

# Least privilege: hanya Describe/List metadata, tanpa membaca isi objek S3 atau rahasia.
resource "aws_iam_role_policy" "baca_metadata" {
  name = "koma-baca-metadata"
  role = aws_iam_role.verifier.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "budgets:ViewBudget",
        "tag:GetResources",
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "s3:GetBucketTagging",
        "s3:GetBucketVersioning",
        "s3:GetLifecycleConfiguration",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketPolicyStatus",
        "s3:GetEncryptionConfiguration",
      ]
      Resource = "*"
    }]
  })
}

output "role_arn" {
  value = aws_iam_role.verifier.arn
}

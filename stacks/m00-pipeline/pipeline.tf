# Identitas pipeline GitHub Actions (Modul 07, dijalankan SEKALI dari laptop dan TIDAK di-destroy
# selama kursus; Modul 08 memakainya lagi). State lokal, seperti m00-pagar.
#
# Tanpa kunci akses: GitHub menerbitkan token OIDC untuk setiap run, AWS memeriksa tanda tangan
# dan isi token (aud, sub), lalu memberi kredensial sementara role koma-<nim>-pipeline selama
# paling lama satu jam. Tidak ada rahasia AWS yang disimpan di GitHub.
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

variable "github_repo" {
  type        = string
  description = "Repo koma-infra Anda di GitHub, berbentuk pemilik/nama (mis. rinaw/koma-infra)"
  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo berbentuk pemilik/nama, tanpa https://github.com/ dan tanpa *."
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
      stack        = "m00-pipeline"
      "managed-by" = "opentofu"
    }
  }
}

data "aws_caller_identity" "saya" {}

locals {
  akun   = data.aws_caller_identity.saya.account_id
  awalan = "koma-${var.nim}-m07"
}

# E.1 Satu provider OIDC per akun untuk GitHub. AWS tidak lagi memakai thumbprint untuk
# token.actions.githubusercontent.com, sehingga daftar thumbprint tidak diisi.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = { Name = "koma-${var.nim}-github-oidc" }
}

# Hanya run dari cabang main (terapkan) dan dari pull request (rencana) di SATU repo yang
# boleh mengambil role ini. Tanpa syarat sub, repo GitHub siapa pun dapat memakainya.
resource "aws_iam_role" "pipeline" {
  name                 = "koma-${var.nim}-pipeline"
  description          = "Dipakai GitHub Actions repo ${var.github_repo} lewat OIDC"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repo}:ref:refs/heads/main",
            "repo:${var.github_repo}:pull_request",
          ]
        }
      }
    }]
  })
  tags = { Name = "koma-${var.nim}-pipeline" }
}

# Batas nama, bukan batas aksi: pipeline boleh mengelola apa pun yang bernama koma-<nim>-m07-*,
# dan tidak boleh menyentuh yang lain (stack modul lain, role verifier, role pipeline sendiri).
resource "aws_iam_role_policy" "pipeline" {
  name = "koma-pipeline-m07"
  role = aws_iam_role.pipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateM07"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::koma-${var.nim}-tfstate-${local.akun}/m07/*"
      },
      {
        # Hanya daftar nama objek. Tanpa syarat prefix: backend S3 juga mendaftar prefix env:/
        # (workspace) saat init.
        Sid      = "DaftarState"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::koma-${var.nim}-tfstate-${local.akun}"
      },
      {
        Sid    = "JalurM07"
        Effect = "Allow"
        Action = ["sns:*", "sqs:*", "lambda:*", "s3:*", "logs:*", "budgets:*"]
        Resource = [
          "arn:aws:sns:${var.region}:${local.akun}:${local.awalan}-*",
          "arn:aws:sqs:${var.region}:${local.akun}:${local.awalan}-*",
          "arn:aws:lambda:${var.region}:${local.akun}:function:${local.awalan}-*",
          "arn:aws:s3:::${local.awalan}-*",
          "arn:aws:s3:::${local.awalan}-*/*",
          "arn:aws:logs:${var.region}:${local.akun}:log-group:/aws/lambda/${local.awalan}-*",
          "arn:aws:budgets::${local.akun}:budget/${local.awalan}-*",
        ]
      },
      {
        Sid    = "RoleFungsi"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole", "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy", "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
        ]
        Resource = "arn:aws:iam::${local.akun}:role/${local.awalan}-*"
      },
      {
        Sid       = "SerahkanRoleKeLambda"
        Effect    = "Allow"
        Action    = "iam:PassRole"
        Resource  = "arn:aws:iam::${local.akun}:role/${local.awalan}-*"
        Condition = { StringEquals = { "iam:PassedToService" = "lambda.amazonaws.com" } }
      },
      {
        Sid       = "PemetaanAntrean"
        Effect    = "Allow"
        Action    = ["lambda:CreateEventSourceMapping", "lambda:UpdateEventSourceMapping", "lambda:DeleteEventSourceMapping"]
        Resource  = "*"
        Condition = { StringLike = { "lambda:FunctionArn" = "arn:aws:lambda:${var.region}:${local.akun}:function:${local.awalan}-*" } }
      },
      {
        Sid      = "TagPemetaanAntrean"
        Effect   = "Allow"
        Action   = ["lambda:GetEventSourceMapping", "lambda:ListTags", "lambda:TagResource", "lambda:UntagResource"]
        Resource = "arn:aws:lambda:${var.region}:${local.akun}:event-source-mapping:*"
      },
      {
        # Aksi baca yang tidak mendukung pembatasan resource.
        Sid      = "BacaTanpaBatasResource"
        Effect   = "Allow"
        Action   = ["lambda:ListEventSourceMappings", "logs:DescribeLogGroups"]
        Resource = "*"
      },
    ]
  })
}

output "role_arn" {
  description = "Salin ke variabel repo GitHub AWS_ROLE_ARN"
  value       = aws_iam_role.pipeline.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

# Stack m08-layanan: API stateless di ECS Fargate di balik ALB, pesanan ke modul antrean-arsip
# (Modul 07) sebagai worker. Semua yang ada di sini dibangun ulang dari nol di Bagian E; registri
# image (m08-registri) dan state tidak.

data "aws_caller_identity" "saya" {}
data "aws_region" "ini" {}

data "aws_vpc" "bawaan" {
  default = true
}

data "aws_subnets" "bawaan" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.bawaan.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Registri dari stack m08-registri. Plan berhenti bila image versi yang diminta belum didorong
# pipeline: kode tidak boleh menyebut image yang tidak ada.
data "aws_ecr_repository" "api" {
  name = "koma-${var.nim}-m08-api"
}

data "aws_ecr_image" "stabil" {
  repository_name = data.aws_ecr_repository.api.name
  image_tag       = var.versi_stabil
}

data "aws_ecr_image" "canary" {
  count           = var.versi_canary == "" ? 0 : 1
  repository_name = data.aws_ecr_repository.api.name
  image_tag       = var.versi_canary
}

locals {
  awalan   = "koma-${var.nim}-m08"
  akun     = data.aws_caller_identity.saya.account_id
  region   = data.aws_region.ini.region
  preset   = { kecil = { cpu = 256, memori = 512 }, sedang = { cpu = 512, memori = 1024 } }
  canary   = var.versi_canary != ""
  log_grup = "/koma/${var.nim}/m08/api"
}

# TODO B.1  module "pesanan" (../../modules/antrean-arsip dari Modul 07; awalan "${local.awalan}-prod",
#           lingkungan prod, ukuran sedang, retensi 1 hari, dengan DLQ, versi 1.0.0)

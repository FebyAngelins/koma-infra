# Modul 06 — versi baru (hijau). Ikuti naskah Bagian C.

data "aws_caller_identity" "saya" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
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

locals {
  awalan    = "koma-${var.nim}-m06"
  akun      = data.aws_caller_identity.saya.account_id
  log_group = "/koma/${var.nim}/m06/api"
}

# TODO C.1  aws_security_group.hijau (VPC bawaan) + ingress HTTP 80 hanya dari SG ALB + egress HTTPS 443
# TODO C.2  aws_iam_role.hijau (dipakai ec2.amazonaws.com) + aws_iam_role_policy.tulis_log
#           (logs:CreateLogStream, PutLogEvents, DescribeLogStreams pada log group local.log_group)
#           + aws_iam_instance_profile.hijau
# TODO C.3  aws_instance.hijau (subnet bawaan pertama, IP publik hanya untuk keluar, SG hijau, instance
#           profile, user_data dari templates/cloud-init-hijau.yaml.tftpl dengan versi, log_group,
#           aplikasi_gz; IMDSv2; disk root terenkripsi; tag peran = "hijau" dan versi = var.versi_hijau).
#           user_data merujuk log group, jadi tulis TODO D.1 di observability.tf bersama langkah ini.

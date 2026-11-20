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

# ----------------------------------------------------------------- versi baru (hijau)

# C.1 Security group server hijau: HTTP hanya dari ALB, keluar hanya HTTPS
resource "aws_security_group" "hijau" {
  name        = "${local.awalan}-hijau"
  description = "koma-api versi baru: HTTP hanya dari ALB"
  vpc_id      = data.aws_vpc.bawaan.id
  tags        = { Name = "${local.awalan}-hijau", peran = "hijau" }
}

resource "aws_vpc_security_group_ingress_rule" "hijau_dari_alb" {
  security_group_id            = aws_security_group.hijau.id
  description                  = "HTTP dari ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# Paket CloudWatch agent dan API CloudWatch Logs dijangkau lewat HTTPS.
# trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "hijau_https" {
  security_group_id = aws_security_group.hijau.id
  description       = "HTTPS ke repositori paket dan endpoint AWS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# C.2 Identitas server hijau: hanya boleh menulis log ke satu log group
resource "aws_iam_role" "hijau" {
  name        = "${local.awalan}-hijau"
  description = "Server hijau: hanya menulis log ke satu log group"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${local.awalan}-hijau", peran = "hijau" }
}

resource "aws_iam_role_policy" "tulis_log" {
  name = "tulis-log-api"
  role = aws_iam_role.hijau.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "TulisLogApi"
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      Resource = "arn:aws:logs:${var.region}:${local.akun}:log-group:${local.log_group}:*"
    }]
  })
}

resource "aws_iam_instance_profile" "hijau" {
  name = "${local.awalan}-hijau"
  role = aws_iam_role.hijau.name
  tags = { Name = "${local.awalan}-hijau", peran = "hijau" }
}

# C.3 Server hijau: IMDSv2 wajib, disk terenkripsi, versi baru = server baru
resource "aws_instance" "hijau" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.bawaan.ids[0]
  associate_public_ip_address = true # hanya untuk keluar (tanpa NAT); ingress hanya dari ALB
  vpc_security_group_ids      = [aws_security_group.hijau.id]
  iam_instance_profile        = aws_iam_instance_profile.hijau.name
  user_data = templatefile("${path.module}/templates/cloud-init-hijau.yaml.tftpl", {
    versi       = var.versi_hijau
    log_group   = aws_cloudwatch_log_group.api.name
    aplikasi_gz = base64gzip(file("${path.module}/../../app/koma_api.py"))
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${local.awalan}-hijau", peran = "hijau", versi = var.versi_hijau }

  lifecycle {
    # Data AMI "most_recent" berganti-ganti antar plan (pola yang sama di K-05); server hanya
    # diganti bila user_data (versi, template, aplikasi) berubah, bukan karena AMI bergeser.
    ignore_changes = [ami]
  }
}

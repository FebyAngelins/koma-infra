# Modul 02 — server sebagai kode: panggang (bake) AMI lalu sajikan (serve).
# Ikuti naskah Bagian B (panggang) dan C (sajikan).

locals {
  awalan = "koma-${var.nim}-m02"
  cloud_init = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    versi       = var.versi
    aplikasi_gz = base64gzip(file("${path.module}/../../app/koma_api.py"))
  })
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_vpc" "bawaan" {
  default = true
}

# ----------------------------------------------------------------- panggang (bake)

# B.1 Server pembangun: AMI publik + cloud-init. Versi baru = user_data baru = pembangun baru.
resource "aws_instance" "pembangun" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = false # pembangun tidak perlu dijangkau siapa pun
  user_data                   = local.cloud_init
  user_data_replace_on_change = true # user data baru -> instance baru -> boot pertama baru

  # layanan metadata hanya menerima token (IMDSv2)
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name  = "${local.awalan}-pembangun"
    peran = "pembangun"
    versi = var.versi
  }
}

# B.2 Instance "running" belum berarti cloud-init selesai; beri jeda sebelum memotret disk.
resource "time_sleep" "tunggu_cloud_init" {
  create_duration = var.tunggu_cloud_init
  triggers = {
    instance = aws_instance.pembangun.id
  }
}

# B.3 AMI berversi milik akun sendiri, dipotret setelah jeda selesai
resource "aws_ami_from_instance" "api" {
  name               = "${local.awalan}-api-${var.versi}"
  source_instance_id = time_sleep.tunggu_cloud_init.triggers["instance"]

  tags = {
    Name  = "${local.awalan}-api-${var.versi}"
    peran = "api"
    versi = var.versi
  }
}

# ----------------------------------------------------------------- sajikan (serve)

# C.1 Satu-satunya jalan masuk: port 80, hanya dari IP praktikan (/32)
resource "aws_security_group" "api" {
  name        = "${local.awalan}-api"
  description = "HTTP koma-api hanya dari komputer praktikan"
  vpc_id      = data.aws_vpc.bawaan.id
  tags = {
    Name  = "${local.awalan}-api"
    peran = "api"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_saya" {
  security_group_id = aws_security_group.api.id
  description       = "HTTP dari IP praktikan"
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# C.2 Server api: dari AMI sendiri, tanpa user_data. Ganti versi -> AMI baru -> instance baru.
resource "aws_instance" "api" {
  ami                         = aws_ami_from_instance.api.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name  = "${local.awalan}-api"
    peran = "api"
    versi = var.versi
  }
}

# Latihan 2.1: server "goreng" (AMI publik + cloud-init saat boot) sebagai pembanding waktu siap
resource "aws_instance" "goreng" {
  count = var.bandingkan_goreng ? 1 : 0

  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]
  user_data                   = local.cloud_init
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name  = "${local.awalan}-goreng"
    peran = "goreng"
    versi = var.versi
  }
}

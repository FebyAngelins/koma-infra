# Modul 04 — stack data. Ikuti naskah Bagian B (block storage) dan C (object storage).
# State stack ini mula-mula lokal; Bagian B.4 memindahkannya ke bucket S3 (backend.tf).

data "aws_caller_identity" "saya" {}

data "aws_availability_zones" "ada" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

locals {
  awalan = "koma-${var.nim}-m04"
  # Volume EBS hanya bisa dipasang ke instance di AZ yang sama.
  az = data.aws_availability_zones.ada.names[0]
}

# ----------------------------------------------------------------- block storage

# Data hidup lebih lama daripada server: volume ini tidak ikut diganti saat versi db naik.
resource "aws_ebs_volume" "data" {
  availability_zone = local.az
  size              = var.ukuran_data_gib
  type              = "gp3"
  encrypted         = true
  tags              = { Name = "${local.awalan}-data", peran = "data" }
}

# Server db: memformat volume hanya bila kosong, lalu menulis penanda ke log konsol.
resource "aws_instance" "db" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  availability_zone           = local.az
  associate_public_ip_address = false
  user_data = templatefile("${path.module}/templates/cloud-init-db.yaml.tftpl", {
    volume_id = aws_ebs_volume.data.id
    versi     = var.versi
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

  tags = { Name = "${local.awalan}-db", peran = "db", versi = var.versi }
}

# Hubungan volume-server: hanya ini yang ikut diganti bila server diganti.
resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.db.id
  # Hentikan server lama sebelum volume dilepas agar sistem berkas tidak rusak.
  stop_instance_before_detaching = true
}

# TODO C.1  aws_s3_bucket.arsip ("${local.awalan}-arsip-<ID akun>", force_destroy = true) beserta
#           versioning, enkripsi AES256, dan public access block
# TODO C.2  aws_s3_bucket_lifecycle_configuration.arsip: versi lama kedaluwarsa var.retensi_versi_hari,
#           laporan/ pindah ke STANDARD_IA setelah 30 hari, tmp/ kedaluwarsa 7 hari
# TODO C.3  aws_s3_object.laporan (laporan/ringkasan-harian.csv, isinya memuat var.versi)

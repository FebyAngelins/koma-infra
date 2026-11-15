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

# ----------------------------------------------------------------- object storage

resource "aws_s3_bucket" "arsip" {
  bucket = "${local.awalan}-arsip-${data.aws_caller_identity.saya.account_id}"
  # Praktikum: izinkan destroy walaupun berisi versi objek.
  force_destroy = true
  tags          = { Name = "${local.awalan}-arsip", peran = "arsip" }
}

resource "aws_s3_bucket_versioning" "arsip" {
  bucket = aws_s3_bucket.arsip.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "arsip" {
  bucket                  = aws_s3_bucket.arsip.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tiga aturan lifecycle: versi lama, laporan dingin, dan berkas sementara.
resource "aws_s3_bucket_lifecycle_configuration" "arsip" {
  bucket     = aws_s3_bucket.arsip.id
  depends_on = [aws_s3_bucket_versioning.arsip]

  rule {
    id     = "versi-lama"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = var.retensi_versi_hari
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "laporan-dingin"
    status = "Enabled"
    filter {
      prefix = "laporan/"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "sementara"
    status = "Enabled"
    filter {
      prefix = "tmp/"
    }
    expiration {
      days = 7
    }
  }
}

# Isi laporan memuat versi db: setiap rilis menambah versi objek, bukan menimpanya.
resource "aws_s3_object" "laporan" {
  bucket       = aws_s3_bucket.arsip.id
  key          = "laporan/ringkasan-harian.csv"
  content      = "tanggal,versi_db,catatan\n2026-11-06,${var.versi},contoh laporan harian\n"
  content_type = "text/csv"
  depends_on   = [aws_s3_bucket_versioning.arsip]
}

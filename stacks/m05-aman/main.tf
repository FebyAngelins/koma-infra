# Modul 05 — stack aman. Ikuti naskah Bagian C: setiap TODO menutup satu temuan stack rawan.
# Enkripsi state (enkripsi.tf) ditulis di Bagian D sebelum `tofu init` pertama.

data "aws_caller_identity" "saya" {}

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

locals {
  awalan    = "koma-${var.nim}-m05"
  akun      = data.aws_caller_identity.saya.account_id
  parameter = "/koma/${var.nim}/m05/db-password"
  # ARN disusun dari nilai yang sudah diketahui saat plan, agar kebijakan IAM dan bucket
  # tampil utuh di plan JSON dan dapat diperiksa Conftest sebelum apply.
  arn_parameter = "arn:aws:ssm:${var.region}:${local.akun}:parameter${local.parameter}"
  bucket        = "${local.awalan}-laporan-${local.akun}"
}

# ----------------------------------------------------------------- kunci (KMS)

# Kunci milik sendiri (customer managed): rotasi tahunan otomatis, dan dapat dibatasi siapa
# pemakainya. Saat destroy, kunci tidak langsung hilang tetapi dijadwalkan dihapus 7 hari lagi.
resource "aws_kms_key" "m05" {
  description             = "Kunci rahasia dan laporan ${local.awalan}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = { Name = "${local.awalan}-kunci", peran = "kunci" }
}

resource "aws_kms_alias" "m05" {
  name          = "alias/${local.awalan}"
  target_key_id = aws_kms_key.m05.key_id
}

# ----------------------------------------------------------------- rahasia

# Rahasia dibangkitkan saat apply, bukan ditulis di kode. Menaikkan putaran_rahasia
# membangkitkan password baru (rotasi) tanpa mengubah kode lain.
resource "random_password" "db" {
  length  = 24
  special = false
  keepers = {
    putaran = var.putaran_rahasia
  }
}

# SecureString: nilai disimpan terenkripsi dengan kunci m05; yang membaca harus punya izin
# ssm:GetParameter pada parameter ini DAN kms:Decrypt pada kuncinya.
resource "aws_ssm_parameter" "db_password" {
  name        = local.parameter
  description = "Password database koma-api (dibangkitkan OpenTofu)"
  type        = "SecureString"
  key_id      = aws_kms_key.m05.arn
  value       = random_password.db.result
  tags        = { Name = "${local.awalan}-db-password", peran = "rahasia" }
}

# ----------------------------------------------------------------- identitas server (IAM)

resource "aws_iam_role" "api" {
  name        = "${local.awalan}-api"
  description = "Identitas server koma-api: hanya membaca satu parameter rahasia"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${local.awalan}-api", peran = "api" }
}

# Least privilege: satu aksi, satu resource.
resource "aws_iam_role_policy" "baca_parameter" {
  name = "baca-parameter-db"
  role = aws_iam_role.api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "BacaPasswordDb"
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = local.arn_parameter
    }]
  })
}

# Dekripsi hanya dengan kunci m05 dan hanya bila permintaannya datang lewat SSM.
resource "aws_iam_role_policy" "dekripsi" {
  name = "dekripsi-lewat-ssm"
  role = aws_iam_role.api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DekripsiParameter"
      Effect   = "Allow"
      Action   = ["kms:Decrypt"]
      Resource = aws_kms_key.m05.arn
      Condition = {
        StringEquals = { "kms:ViaService" = "ssm.${var.region}.amazonaws.com" }
      }
    }]
  })
}

resource "aws_iam_instance_profile" "api" {
  name = "${local.awalan}-api"
  role = aws_iam_role.api.name
  tags = { Name = "${local.awalan}-api", peran = "api" }
}

# ----------------------------------------------------------------- jaringan

resource "aws_security_group" "api" {
  name        = "${local.awalan}-api"
  description = "HTTP koma-api hanya dari komputer praktikan; tanpa port admin"
  vpc_id      = data.aws_vpc.bawaan.id
  tags        = { Name = "${local.awalan}-api", peran = "api" }
}

resource "aws_vpc_security_group_ingress_rule" "http_saya" {
  security_group_id = aws_security_group.api.id
  description       = "HTTP dari IP praktikan"
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# Server perlu HTTPS keluar untuk memanggil API SSM dan KMS saat boot. Membatasinya ke VPC
# endpoint berbayar per jam per AZ, jadi temuan Trivy ini diterima (log keputusan K-05).
# trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "https_keluar" {
  security_group_id = aws_security_group.api.id
  description       = "HTTPS ke endpoint AWS (SSM, KMS)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# ----------------------------------------------------------------- server

resource "aws_instance" "api" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.api.id]
  iam_instance_profile        = aws_iam_instance_profile.api.name
  # user_data hanya memuat NAMA parameter, bukan nilainya.
  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    versi       = var.versi
    region      = var.region
    parameter   = aws_ssm_parameter.db_password.name
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

  tags = { Name = "${local.awalan}-api", peran = "api", versi = var.versi }

  # Filter AMI cocok dengan lebih dari satu image AL2023 terbaru, sehingga ID-nya dapat
  # berganti antar-plan dan memaksa server diganti. Rotasi rahasia tidak boleh mengganti
  # server; versi image baru dipasang lewat perubahan versi/user_data, bukan diam-diam.
  lifecycle {
    ignore_changes = [ami]
  }
}

# ----------------------------------------------------------------- object storage

# Logging akses dan versioning tidak dipakai di praktikum (bucket dibongkar di akhir sesi);
# keduanya diterima sebagai risiko sisa di laporan audit.
# trivy:ignore:AWS-0089
# trivy:ignore:AWS-0090
resource "aws_s3_bucket" "laporan" {
  bucket = local.bucket
  # Praktikum: izinkan destroy walaupun berisi objek.
  force_destroy = true
  tags          = { Name = "${local.awalan}-laporan", peran = "laporan" }
}

resource "aws_s3_bucket_public_access_block" "laporan" {
  bucket                  = aws_s3_bucket.laporan.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "laporan" {
  bucket = aws_s3_bucket.laporan.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "laporan" {
  bucket = aws_s3_bucket.laporan.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.m05.arn
    }
    bucket_key_enabled = true
  }
}

# Principal "*" di sini aman karena Effect-nya Deny: menolak akses tanpa TLS dari siapa pun.
resource "aws_s3_bucket_policy" "laporan" {
  bucket     = aws_s3_bucket.laporan.id
  depends_on = [aws_s3_bucket_public_access_block.laporan]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "HanyaTLS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = ["arn:aws:s3:::${local.bucket}", "arn:aws:s3:::${local.bucket}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_object" "laporan" {
  bucket       = aws_s3_bucket.laporan.id
  key          = "laporan/pelanggan-contoh.csv"
  content      = "id,nama,kelas_data\n1,Pelanggan Contoh,rahasia\n"
  content_type = "text/csv"
  depends_on   = [aws_s3_bucket_server_side_encryption_configuration.laporan]
}

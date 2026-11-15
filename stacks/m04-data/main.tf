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

# TODO B.1  aws_ebs_volume.data (local.az, var.ukuran_data_gib, gp3, terenkripsi, tag peran = "data")
# TODO B.2  aws_instance.db (local.az, tanpa IP publik, user_data dari templates/cloud-init-db.yaml.tftpl
#           dengan volume_id dan versi, user_data_replace_on_change = true, tag peran = "db" dan versi)
# TODO B.3  aws_volume_attachment.data (/dev/sdf, stop_instance_before_detaching = true)

# TODO C.1  aws_s3_bucket.arsip ("${local.awalan}-arsip-<ID akun>", force_destroy = true) beserta
#           versioning, enkripsi AES256, dan public access block
# TODO C.2  aws_s3_bucket_lifecycle_configuration.arsip: versi lama kedaluwarsa var.retensi_versi_hari,
#           laporan/ pindah ke STANDARD_IA setelah 30 hari, tmp/ kedaluwarsa 7 hari
# TODO C.3  aws_s3_object.laporan (laporan/ringkasan-harian.csv, isinya memuat var.versi)

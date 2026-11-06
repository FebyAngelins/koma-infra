# Modul 01 — stack sandbox. Ikuti naskah Bagian B lalu C.

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Bagian B: satu server web yang ditulis sebagai kode (keadaan akhir yang diinginkan)
resource "aws_instance" "web" {
  # image dari data source, bukan ID AMI yang diketik tangan
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = false # tanpa IP publik

  # layanan metadata hanya menerima token (IMDSv2)
  metadata_options {
    http_tokens = "required"
  }

  # disk akar 8 GiB gp3 terenkripsi, ditulis eksplisit agar tidak bergantung bawaan
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  # tag khusus resource ini; tag wajib lain datang dari default_tags di provider
  tags = {
    Name   = "koma-${var.nim}-m01-web"
    peran  = "web"
    ukuran = "kecil"
  }
}

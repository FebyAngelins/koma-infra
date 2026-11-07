# Modul 03 — stack jaringan. Ikuti naskah Bagian A.

data "aws_availability_zones" "ada" {
  state = "available"
}

locals {
  awalan = "koma-${var.nim}-m03"
  # Dua AZ pertama; kunci peta = huruf akhir nama AZ (a, b) agar nama resource stabil.
  azs = { for i, az in slice(data.aws_availability_zones.ada.names, 0, 2) : substr(az, -1, 1) => { az = az, i = i } }
}

# ----------------------------------------------------------------- A.2 VPC, SG bawaan, IGW

# Ruang alamat milik sendiri; semua subnet diturunkan dari var.cidr_vpc
resource "aws_vpc" "utama" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name  = "${local.awalan}-vpc"
    peran = "vpc"
  }
}

# Default-deny: security group bawaan VPC dikosongkan (tanpa aturan masuk/keluar).
resource "aws_default_security_group" "bawaan" {
  vpc_id = aws_vpc.utama.id
  tags = {
    Name  = "${local.awalan}-sg-bawaan"
    peran = "bawaan"
  }
}

# Pintu VPC ke internet; hanya dipakai route table publik
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.utama.id
  tags = {
    Name  = "${local.awalan}-igw"
    peran = "igw"
  }
}

# ----------------------------------------------------------------- A.3 subnet

# Subnet publik: hanya untuk load balancer; tidak memberi IP publik otomatis.
resource "aws_subnet" "publik" {
  for_each                = local.azs
  vpc_id                  = aws_vpc.utama.id
  availability_zone       = each.value.az
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, each.value.i)
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.awalan}-publik-${each.key}"
    tier = "publik"
  }
}

# Subnet privat: server aplikasi dan basis data; tanpa rute ke internet.
resource "aws_subnet" "privat" {
  for_each                = local.azs
  vpc_id                  = aws_vpc.utama.id
  availability_zone       = each.value.az
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, each.value.i + 10)
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.awalan}-privat-${each.key}"
    tier = "privat"
  }
}

# ----------------------------------------------------------------- A.4 route table

# Publik = punya rute 0.0.0.0/0 ke IGW
resource "aws_route_table" "publik" {
  vpc_id = aws_vpc.utama.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.awalan}-rt-publik"
    tier = "publik"
  }
}

# Tanpa NAT Gateway (±USD 45/bulan): subnet privat sengaja tidak punya jalan keluar.
resource "aws_route_table" "privat" {
  vpc_id = aws_vpc.utama.id
  tags = {
    Name = "${local.awalan}-rt-privat"
    tier = "privat"
  }
}

resource "aws_route_table_association" "publik" {
  for_each       = aws_subnet.publik
  subnet_id      = each.value.id
  route_table_id = aws_route_table.publik.id
}

resource "aws_route_table_association" "privat" {
  for_each       = aws_subnet.privat
  subnet_id      = each.value.id
  route_table_id = aws_route_table.privat.id
}

# Modul 03 — stack aplikasi. Ikuti naskah Bagian B dan C.

# Stack aplikasi membaca stack jaringan hanya lewat output-nya (kontrak antarstack).
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "${path.module}/../m03-network/terraform.tfstate"
  }
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
  awalan     = "koma-${var.nim}-m03"
  jaringan   = data.terraform_remote_state.network.outputs
  aplikasi   = base64gzip(file("${path.module}/../../app/koma_api.py"))
  web        = { for i in range(var.jumlah_web) : "web-${i + 1}" => i }
  cloud_init = { for peran, port in { web = 80, db = 5432 } : peran => templatefile("${path.module}/templates/cloud-init.yaml.tftpl", { versi = var.versi, peran = peran, port = port, aplikasi_gz = local.aplikasi }) }
}

# ----------------------------------------------------------------- B.1 security group

resource "aws_security_group" "alb" {
  name        = "${local.awalan}-alb"
  description = "Load balancer: HTTP hanya dari komputer praktikan"
  vpc_id      = local.jaringan.vpc_id
  tags        = { Name = "${local.awalan}-alb", peran = "alb" }
}

resource "aws_security_group" "web" {
  name        = "${local.awalan}-web"
  description = "Server web: HTTP hanya dari load balancer"
  vpc_id      = local.jaringan.vpc_id
  tags        = { Name = "${local.awalan}-web", peran = "web" }
}

resource "aws_security_group" "db" {
  name        = "${local.awalan}-db"
  description = "Basis data: 5432 hanya dari server web"
  vpc_id      = local.jaringan.vpc_id
  tags        = { Name = "${local.awalan}-db", peran = "db" }
}

# ----------------------------------------------------------------- B.2 lima aturan dari matriks

# laptop (/32) -> alb:80 ; satu-satunya aturan berbasis CIDR
resource "aws_vpc_security_group_ingress_rule" "alb_dari_saya" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# alb -> web:80 (sisi keluar alb)
resource "aws_vpc_security_group_egress_rule" "alb_ke_web" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# alb -> web:80 (sisi masuk web)
resource "aws_vpc_security_group_ingress_rule" "web_dari_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# web -> db:5432 (sisi keluar web)
resource "aws_vpc_security_group_egress_rule" "web_ke_db" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# web -> db:5432 (sisi masuk db); db sendiri tidak punya aturan keluar
resource "aws_vpc_security_group_ingress_rule" "db_dari_web" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# ----------------------------------------------------------------- C.1 server

# Server web di subnet privat, tersebar di dua AZ, tanpa IP publik
resource "aws_instance" "web" {
  for_each = local.web

  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = element(local.jaringan.subnet_privat_ids, each.value)
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data                   = local.cloud_init["web"]
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${local.awalan}-${each.key}", peran = "web", versi = var.versi }
}

# Server db (koma_api.py di port 5432) di subnet privat pertama
resource "aws_instance" "db" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = local.jaringan.subnet_privat_ids[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.db.id]
  user_data                   = local.cloud_init["db"]
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

# ----------------------------------------------------------------- C.2 load balancer

# Satu pintu masuk internet-facing di dua subnet publik
resource "aws_lb" "app" {
  name               = local.awalan
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.jaringan.subnet_publik_ids
  tags               = { Name = "${local.awalan}-alb", peran = "alb" }
}

# Target group dengan health check GET /health tiap 10 detik
resource "aws_lb_target_group" "web" {
  name     = "${local.awalan}-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.jaringan.vpc_id

  health_check {
    path                = "/health"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = { Name = "${local.awalan}-tg-web", peran = "web" }
}

# Setiap server web otomatis terdaftar sebagai target
resource "aws_lb_target_group_attachment" "web" {
  for_each         = aws_instance.web
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = each.value.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  tags = { Name = "${local.awalan}-listener", peran = "alb" }
}

# Modul 06 — satu alamat untuk dua versi. Ikuti naskah Bagian C.

# C.4 Security group ALB: masuk HTTP hanya dari IP praktikan, keluar HTTP ke VPC bawaan
resource "aws_security_group" "alb" {
  name        = "${local.awalan}-alb"
  description = "ALB koma-api: HTTP hanya dari komputer praktikan"
  vpc_id      = data.aws_vpc.bawaan.id
  tags        = { Name = "${local.awalan}-alb", peran = "alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP dari IP praktikan"
  cidr_ipv4         = var.cidr_saya
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_ke_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP ke server di VPC bawaan"
  cidr_ipv4         = data.aws_vpc.bawaan.cidr_block
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# C.5 ALB dan dua target group (biru = legacy, hijau = versi baru)
# Praktikum: ALB publik di VPC bawaan, dibatasi security group ke /32 praktikan.
# trivy:ignore:AWS-0053
resource "aws_lb" "api" {
  name                       = local.awalan
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.aws_subnets.bawaan.ids
  drop_invalid_header_fields = true
  tags                       = { Name = local.awalan, peran = "alb" }
}

resource "aws_lb_target_group" "biru" {
  count                = var.pertahankan_legacy ? 1 : 0
  name                 = "${local.awalan}-biru"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.bawaan.id
  deregistration_delay = 5
  health_check {
    path                = "/health"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${local.awalan}-biru", peran = "biru" }
}

resource "aws_lb_target_group_attachment" "biru" {
  count            = var.pertahankan_legacy ? 1 : 0
  target_group_arn = aws_lb_target_group.biru[0].arn
  target_id        = aws_instance.legacy[0].id
  port             = 80
}

resource "aws_lb_target_group" "hijau" {
  name                 = "${local.awalan}-hijau"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.bawaan.id
  deregistration_delay = 5
  health_check {
    path                = "/health"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${local.awalan}-hijau", peran = "hijau" }
}

resource "aws_lb_target_group_attachment" "hijau" {
  target_group_arn = aws_lb_target_group.hijau.arn
  target_id        = aws_instance.hijau.id
  port             = 80
}

# C.6 Listener sebagai titik alih: satu atribut (var.aktif) memilih target group
locals {
  tg_aktif = var.aktif == "biru" ? one(aws_lb_target_group.biru[*].arn) : aws_lb_target_group.hijau.arn
}

# Praktikum tanpa domain dan sertifikat: HTTP saja, hanya dari /32 praktikan.
# trivy:ignore:AWS-0054
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = local.tg_aktif
  }

  lifecycle {
    precondition {
      condition     = var.aktif == "hijau" || var.pertahankan_legacy
      error_message = "Lalu lintas tidak dapat diarahkan ke biru setelah legacy dibongkar (pertahankan_legacy = false). Pakai aktif = \"hijau\"."
    }
  }
}

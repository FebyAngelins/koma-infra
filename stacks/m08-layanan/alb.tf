# Satu alamat untuk dua versi (Bagian B.4).

resource "aws_security_group" "alb" {
  name        = "${local.awalan}-alb"
  description = "ALB layanan m08: HTTP hanya dari komputer praktikan"
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

resource "aws_vpc_security_group_egress_rule" "alb_ke_task" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Ke task di port 8080"
  referenced_security_group_id = aws_security_group.task.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_security_group" "task" {
  name        = "${local.awalan}-task"
  description = "Task API m08: 8080 hanya dari ALB, keluar HTTPS"
  vpc_id      = data.aws_vpc.bawaan.id
  tags        = { Name = "${local.awalan}-task", peran = "task" }
}

resource "aws_vpc_security_group_ingress_rule" "task_dari_alb" {
  security_group_id            = aws_security_group.task.id
  description                  = "8080 dari ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

# Praktikum: task menarik image dari ECR dan menerbitkan ke SNS lewat internet (tanpa NAT dan
# tanpa VPC endpoint berbayar), sehingga keluar HTTPS ke mana saja.
# trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "task_https" {
  security_group_id = aws_security_group.task.id
  description       = "HTTPS keluar (ECR, SNS, CloudWatch Logs)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

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

resource "aws_lb_target_group" "api" {
  for_each             = local.jalur
  name                 = "${local.awalan}-${each.key}"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.bawaan.id
  deregistration_delay = 10
  health_check {
    path                = "/health"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${local.awalan}-${each.key}", peran = each.key }
}

# Listener berbobot: stabil 100 - bobot_canary, canary bobot_canary bila ada.
# trivy:ignore:AWS-0054
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.api["stabil"].arn
        weight = 100 - var.bobot_canary
      }
      dynamic "target_group" {
        for_each = local.canary ? [1] : []
        content {
          arn    = aws_lb_target_group.api["canary"].arn
          weight = var.bobot_canary
        }
      }
    }
  }
}

# Modul 06 — satu alamat untuk dua versi. Ikuti naskah Bagian C.

# TODO C.4  aws_security_group.alb + ingress HTTP 80 dari var.cidr_saya + egress HTTP 80 ke CIDR VPC bawaan
# TODO C.5  aws_lb.api (name = local.awalan, subnet bawaan), target group biru (count, legacy) dan hijau
#           (health check /health, deregistration_delay 5), dan attachment masing-masing
# TODO C.6  local.tg_aktif dari var.aktif dan aws_lb_listener.http (port 80, forward ke local.tg_aktif,
#           precondition: aktif = "hijau" atau pertahankan_legacy)

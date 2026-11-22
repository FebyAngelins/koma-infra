# Satu alamat untuk dua versi. Ikuti naskah Bagian B.4.

# TODO B.4  aws_security_group.alb (80 dari var.cidr_saya; keluar 8080 ke SG task) dan
#           aws_security_group.task (8080 dari SG ALB; keluar 443)
# TODO B.4  aws_lb.api (local.awalan, subnet bawaan), aws_lb_target_group.api (for_each local.jalur,
#           target_type ip, port 8080, health /health), aws_lb_listener.http (forward berbobot:
#           stabil 100 - var.bobot_canary, canary var.bobot_canary bila ada)

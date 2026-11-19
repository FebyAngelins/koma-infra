# Modul 06 — server legacy warisan kontraktor. Ikuti naskah Bagian B: tulis resource yang SAMA
# PERSIS dengan yang dibuat `koma legacy buat`, lalu impor dengan blok import di impor.tf.

data "aws_vpc" "bawaan" {
  default = true
}

# TODO B.2  aws_security_group.legacy (count = var.pertahankan_legacy ? 1 : 0; name "${local.awalan}-legacy",
#           description "Web lama koma-api (dibuat manual)", VPC bawaan, tag peran = "legacy"),
#           aws_vpc_security_group_ingress_rule.legacy_http (count; tcp 80 dari var.cidr_saya,
#           description "HTTP dari kantor"), dan aws_instance.legacy (count; t3.micro, AMI al2023,
#           SG legacy, tag peran = "legacy" dan versi = "0.9.0", ignore_changes ami dan user data)
# TODO C.4  aws_vpc_security_group_ingress_rule.legacy_dari_alb (count; HTTP 80 dari SG ALB)

# B.5 Keluaran stack m08-layanan
output "alb_url" {
  value = "http://${aws_lb.api.dns_name}"
}

output "cluster" {
  value = aws_ecs_cluster.ini.name
}

output "versi" {
  value = { for k, v in local.jalur : k => v.versi }
}

output "bobot_canary" {
  value = var.bobot_canary
}

output "topik_arn" {
  value = module.pesanan.topik_arn
}

output "bucket_arsip" {
  value = module.pesanan.bucket
}

output "log_grup" {
  value = aws_cloudwatch_log_group.api.name
}

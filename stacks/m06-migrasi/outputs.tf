# C.6 Output untuk probe dan bukti
output "alb_url" {
  description = "Satu alamat untuk kedua versi (hanya dari IP Anda)"
  value       = "http://${aws_lb.api.dns_name}"
}

output "aktif" {
  value = var.aktif
}

output "id_hijau" {
  value = aws_instance.hijau.id
}

output "log_group" {
  value = aws_cloudwatch_log_group.api.name
}

# TODO D.4: dasbor (tautan konsol CloudWatch).

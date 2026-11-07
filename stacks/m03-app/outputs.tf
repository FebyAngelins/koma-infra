# C.3 Satu-satunya alamat untuk pengguna, dan alamat privat untuk membuktikan server tak terjangkau langsung
output "url_lb" {
  value = "http://${aws_lb.app.dns_name}"
}

output "ip_privat" {
  value = merge({ for k, i in aws_instance.web : k => i.private_ip }, { db = aws_instance.db.private_ip })
}

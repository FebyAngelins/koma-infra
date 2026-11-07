# Kontrak antarstack: hanya nilai ini yang boleh dibaca stack m03-app.
output "vpc_id" {
  value = aws_vpc.utama.id
}

output "cidr_vpc" {
  value = aws_vpc.utama.cidr_block
}

# Daftar terurut menurut kunci AZ (a, b): consumer cukup tahu "subnet pertama dan kedua"
output "subnet_publik_ids" {
  value = [for k in sort(keys(aws_subnet.publik)) : aws_subnet.publik[k].id]
}

output "subnet_privat_ids" {
  value = [for k in sort(keys(aws_subnet.privat)) : aws_subnet.privat[k].id]
}

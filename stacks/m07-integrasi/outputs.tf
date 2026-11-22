# A.5 Keluaran stack m07-integrasi
output "lingkungan" {
  value = var.lingkungan
}

output "topik_arn" {
  value = module.jalur.topik_arn
}

output "bucket_arsip" {
  value = module.jalur.bucket
}

output "fungsi" {
  value = module.jalur.fungsi
}

output "dlq_url" {
  value = module.jalur.dlq_url
}

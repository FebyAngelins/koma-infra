# A.4 Keluaran modul antrean-arsip
output "topik_arn" {
  value = aws_sns_topic.pesanan.arn
}

output "antrean_url" {
  value = aws_sqs_queue.antrean.url
}

output "dlq_url" {
  value = var.dengan_dlq ? aws_sqs_queue.gagal[0].url : null
}

output "bucket" {
  value = aws_s3_bucket.arsip.bucket
}

output "fungsi" {
  value = aws_lambda_function.pengarsip.function_name
}

output "memori_mb" {
  value = aws_lambda_function.pengarsip.memory_size
}

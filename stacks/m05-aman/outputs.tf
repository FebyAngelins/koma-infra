output "api_url" {
  description = "Alamat koma-api (hanya dapat dibuka dari IP Anda)"
  value       = "http://${aws_instance.api.public_ip}"
}

output "parameter_rahasia" {
  description = "NAMA parameter password database (bukan nilainya)"
  value       = aws_ssm_parameter.db_password.name
}

output "kunci_kms" {
  value = aws_kms_alias.m05.name
}

output "bucket_laporan" {
  value = aws_s3_bucket.laporan.bucket
}

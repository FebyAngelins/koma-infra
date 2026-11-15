output "volume_data" {
  value = aws_ebs_volume.data.id
}

output "db" {
  value = aws_instance.db.id
}

output "perintah_penanda" {
  description = "Membaca penanda data dari log konsol server db"
  value       = "aws ec2 get-console-output --instance-id ${aws_instance.db.id} --latest --output text"
}

# TODO C.4: bucket_arsip.

# Modul antrean-arsip (Modul 07, ikuti naskah Bagian A): satu jalur integrasi pesanan per lingkungan (H3, H4).
#
#   aws sns publish ─► topik -pesanan ─► antrean -antrean ─► fungsi -pengarsip ─► bucket -arsip
#                                              │ gagal 3x (bila dengan_dlq)
#                                              └──────────► antrean -gagal
#
# ARN yang dipakai kebijakan IAM disusun dari nama (bukan dari atribut resource) agar isi
# kebijakan sudah diketahui saat plan dan dapat dibaca gerbang Conftest (lihat Modul 05,
# after_unknown).

data "aws_caller_identity" "ini" {}
data "aws_region" "ini" {}

locals {
  akun         = data.aws_caller_identity.ini.account_id
  region       = data.aws_region.ini.region
  memori       = { kecil = 128, sedang = 256 }
  bucket       = "${var.awalan}-arsip-${local.akun}"
  nama_antrean = "${var.awalan}-antrean"
  arn_antrean  = "arn:aws:sqs:${local.region}:${local.akun}:${local.nama_antrean}"
  log_group    = "/aws/lambda/${var.awalan}-pengarsip"
  arn_log      = "arn:aws:logs:${local.region}:${local.akun}:log-group:${local.log_group}"
}

# ---------------------------------------------------------------- A.2 topik, antrean, langganan

resource "aws_sns_topic" "pesanan" {
  name = "${var.awalan}-pesanan"
  tags = { Name = "${var.awalan}-pesanan", peran = "topik" }
}

# DLQ bersyarat: dev tanpa DLQ, prod dengan DLQ, dari kode yang sama.
resource "aws_sqs_queue" "gagal" {
  count                     = var.dengan_dlq ? 1 : 0
  name                      = "${var.awalan}-gagal"
  message_retention_seconds = 345600
  sqs_managed_sse_enabled   = true
  tags                      = { Name = "${var.awalan}-gagal", peran = "dlq" }
}

resource "aws_sqs_queue" "antrean" {
  name                       = local.nama_antrean
  visibility_timeout_seconds = 30 # >= timeout fungsi; pesan gagal terlihat lagi setelah 30 det
  message_retention_seconds  = 86400
  sqs_managed_sse_enabled    = true
  redrive_policy = var.dengan_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.gagal[0].arn
    maxReceiveCount     = 3
  }) : null
  tags = { Name = local.nama_antrean, peran = "antrean" }
}

# Hanya topik modul ini yang boleh mengirim ke antrean.
resource "aws_sqs_queue_policy" "dari_topik" {
  queue_url = aws_sqs_queue.antrean.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DariTopikPesanan"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.antrean.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.pesanan.arn } }
    }]
  })
}

resource "aws_sns_topic_subscription" "antrean" {
  topic_arn            = aws_sns_topic.pesanan.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.antrean.arn
  raw_message_delivery = true
  depends_on           = [aws_sqs_queue_policy.dari_topik]
}

# ---------------------------------------------------------------- A.3 bucket arsip

resource "aws_s3_bucket" "arsip" {
  bucket        = local.bucket
  force_destroy = true # bucket lab: objek ikut terhapus saat destroy
  tags          = { Name = local.bucket, peran = "arsip" }
}

resource "aws_s3_bucket_public_access_block" "arsip" {
  bucket                  = aws_s3_bucket.arsip.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "arsip" {
  bucket = aws_s3_bucket.arsip.id
  rule {
    id     = "retensi-arsip"
    status = "Enabled"
    filter {
      prefix = "arsip/"
    }
    expiration {
      days = var.retensi_hari
    }
  }
}

# ---------------------------------------------------------------- A.4 fungsi pengarsip dan identitasnya

resource "aws_cloudwatch_log_group" "pengarsip" {
  name              = local.log_group
  retention_in_days = 1
  tags              = { Name = local.log_group, peran = "log" }
}

resource "aws_iam_role" "pengarsip" {
  name = "${var.awalan}-pengarsip"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${var.awalan}-pengarsip", peran = "pengarsip" }
}

# Tiga hak sempit: mengambil pesan dari antreannya sendiri, menulis ke arsip/, menulis log.
resource "aws_iam_role_policy" "pengarsip" {
  name = "pengarsip-minimal"
  role = aws_iam_role.pengarsip.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AmbilPesan"
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"]
        Resource = local.arn_antrean
      },
      {
        Sid      = "TulisArsip"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${local.bucket}/arsip/*"
      },
      {
        Sid      = "TulisLog"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${local.arn_log}:*"
      },
    ]
  })
}

data "archive_file" "pengarsip" {
  type        = "zip"
  source_file = "${path.module}/fungsi/pengarsip.py"
  output_path = "${path.root}/.build/pengarsip-${var.lingkungan}.zip"
}

resource "aws_lambda_function" "pengarsip" {
  function_name    = "${var.awalan}-pengarsip"
  role             = aws_iam_role.pengarsip.arn
  runtime          = "python3.12"
  handler          = "pengarsip.handler"
  filename         = data.archive_file.pengarsip.output_path
  source_code_hash = data.archive_file.pengarsip.output_base64sha256
  memory_size      = local.memori[var.ukuran]
  timeout          = 10

  environment {
    variables = {
      BUCKET     = aws_s3_bucket.arsip.id
      LINGKUNGAN = var.lingkungan
      VERSI      = var.versi
    }
  }

  tags       = { Name = "${var.awalan}-pengarsip", peran = "pengarsip", versi = var.versi }
  depends_on = [aws_cloudwatch_log_group.pengarsip, aws_iam_role_policy.pengarsip]
}

resource "aws_lambda_event_source_mapping" "antrean" {
  event_source_arn        = aws_sqs_queue.antrean.arn
  function_name           = aws_lambda_function.pengarsip.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
  enabled                 = true
}

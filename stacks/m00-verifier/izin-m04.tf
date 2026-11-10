# Modul 04: verifier juga perlu mendaftar objek (nama dan versinya saja, tanpa isi) di bucket
# state dan bucket arsip. Berkas ini ditambahkan `koma ambil koma-m04-starter.zip`; terapkan
# ulang stack m00-verifier setelahnya.
resource "aws_iam_role_policy" "baca_m04" {
  name = "koma-baca-daftar-objek"
  role = aws_iam_role.verifier.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:ListBucket", "s3:ListBucketVersions"]
      Resource = "arn:aws:s3:::koma-${var.nim}-*"
    }]
  })
}

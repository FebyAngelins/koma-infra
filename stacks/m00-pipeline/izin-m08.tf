# Modul 08: pipeline boleh mendorong image ke registri koma-<nim>-m08-* saja. Ditambahkan
# `koma ambil koma-m08-starter.zip`; terapkan ulang stack m00-pipeline setelahnya.
resource "aws_iam_role_policy" "pipeline_m08" {
  name = "koma-pipeline-m08"
  role = aws_iam_role.pipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Token login registri berlaku untuk seluruh akun; aksi ini tidak mengenal batas resource.
        Sid      = "MasukRegistri"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "DorongImageM08"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:DescribeImages",
          "ecr:DescribeRepositories",
        ]
        Resource = "arn:aws:ecr:${var.region}:${local.akun}:repository/koma-${var.nim}-m08-*"
      },
    ]
  })
}

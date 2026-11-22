# Modul 08: verifier membaca metadata registri, cluster, layanan, task definition, dan aturan
# skala, tanpa membaca isi image atau log. Task definition memuat variabel lingkungan task;
# verifier hanya memakai nama image-nya, dan modul ini tidak menaruh rahasia di sana. Ditambahkan
# `koma ambil koma-m08-starter.zip`; terapkan ulang stack m00-verifier setelahnya.
resource "aws_iam_role_policy" "baca_m08" {
  name = "koma-baca-kontainer"
  role = aws_iam_role.verifier.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "Kontainer"
      Effect = "Allow"
      Action = [
        "ecr:DescribeRepositories", "ecr:DescribeImages", "ecr:ListTagsForResource",
        "ecs:ListClusters", "ecs:DescribeClusters", "ecs:ListServices", "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "application-autoscaling:DescribeScalableTargets", "application-autoscaling:DescribeScalingPolicies",
        "application-autoscaling:DescribeScalingActivities",
      ]
      Resource = "*"
    }]
  })
}

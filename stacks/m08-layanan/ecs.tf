# Cluster, identitas task, dan layanan stabil/canary (Bagian B).

# ---------------------------------------------------------------- B.2 cluster, log, dua identitas

resource "aws_ecs_cluster" "ini" {
  name = local.awalan
  setting {
    name  = "containerInsights"
    value = "disabled" # metrik dasar layanan cukup; Container Insights ditagih per metrik
  }
  tags = { Name = local.awalan, peran = "cluster" }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = local.log_grup
  retention_in_days = 1
  tags              = { Name = local.log_grup, peran = "log" }
}

# Role eksekusi: dipakai agen ECS untuk menarik image dan menulis log, bukan oleh aplikasi.
resource "aws_iam_role" "eksekusi" {
  name = "${local.awalan}-eksekusi"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${local.awalan}-eksekusi", peran = "eksekusi" }
}

resource "aws_iam_role_policy" "eksekusi" {
  name = "tarik-image-tulis-log"
  role = aws_iam_role.eksekusi.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Sid = "Masuk", Effect = "Allow", Action = "ecr:GetAuthorizationToken", Resource = "*" },
      {
        Sid      = "TarikImage"
        Effect   = "Allow"
        Action   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability"]
        Resource = data.aws_ecr_repository.api.arn
      },
      {
        Sid      = "TulisLog"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${local.region}:${local.akun}:log-group:${local.log_grup}:*"
      },
    ]
  })
}

# Role task: dipakai aplikasi. Satu-satunya hak: menerbitkan ke topik pesanan.
resource "aws_iam_role" "api" {
  name = "${local.awalan}-api"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${local.awalan}-api", peran = "api" }
}

resource "aws_iam_role_policy" "api" {
  name = "terbitkan-pesanan"
  role = aws_iam_role.api.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Sid = "Terbitkan", Effect = "Allow", Action = "sns:Publish", Resource = module.pesanan.topik_arn }]
  })
}

# ---------------------------------------------------------------- B.3 task definition dan layanan

locals {
  jalur = merge(
    { stabil = { versi = var.versi_stabil, digest = data.aws_ecr_image.stabil.image_digest } },
    local.canary ? { canary = { versi = var.versi_canary, digest = data.aws_ecr_image.canary[0].image_digest } } : {}
  )
}

resource "aws_ecs_task_definition" "api" {
  for_each                 = local.jalur
  family                   = "${local.awalan}-api-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.preset[var.ukuran].cpu
  memory                   = local.preset[var.ukuran].memori
  execution_role_arn       = aws_iam_role.eksekusi.arn
  task_role_arn            = aws_iam_role.api.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name                   = "api"
    image                  = "${data.aws_ecr_repository.api.repository_url}:${each.value.versi}"
    essential              = true
    readonlyRootFilesystem = true
    portMappings           = [{ containerPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "KOMA_TOPIK_ARN", value = module.pesanan.topik_arn },
      { name = "KOMA_PERAN", value = each.key },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = local.region
        awslogs-stream-prefix = each.key
      }
    }
  }])

  tags = { Name = "${local.awalan}-api-${each.key}", peran = each.key, versi = each.value.versi }
}

resource "aws_ecs_service" "api" {
  for_each                          = local.jalur
  name                              = "${local.awalan}-${each.key}"
  cluster                           = aws_ecs_cluster.ini.id
  task_definition                   = aws_ecs_task_definition.api[each.key].arn
  launch_type                       = "FARGATE"
  desired_count                     = 1
  health_check_grace_period_seconds = 30
  enable_ecs_managed_tags           = true
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Subnet bawaan dengan IP publik agar task dapat menarik image dari ECR tanpa NAT Gateway;
  # security group task tetap hanya menerima dari ALB.
  network_configuration {
    subnets          = data.aws_subnets.bawaan.ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api[each.key].arn
    container_name   = "api"
    container_port   = 8080
  }

  # Jumlah task stabil diatur auto scaling, bukan kode.
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags       = { Name = "${local.awalan}-${each.key}", peran = each.key, versi = each.value.versi }
  depends_on = [aws_lb_listener.http]
}

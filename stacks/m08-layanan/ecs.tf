# Cluster, identitas task, dan layanan stabil/canary. Ikuti naskah Bagian B.

# TODO B.2  aws_ecs_cluster.ini (local.awalan, containerInsights disabled) dan
#           aws_cloudwatch_log_group.api (local.log_grup, retensi 1 hari)
# TODO B.2  aws_iam_role.eksekusi + aws_iam_role_policy.eksekusi (token ECR, tarik image dari repo ini,
#           tulis log grup ini) dan aws_iam_role.api + aws_iam_role_policy.api (sns:Publish ke topik pesanan)
# TODO B.3  local.jalur (stabil, dan canary bila var.versi_canary diisi), aws_ecs_task_definition.api
#           (for_each local.jalur; Fargate, awsvpc, preset ukuran, readonlyRootFilesystem, env KOMA_TOPIK_ARN
#           dan KOMA_PERAN, log awslogs) dan aws_ecs_service.api (for_each; subnet bawaan, IP publik,
#           circuit breaker + rollback, load_balancer ke target group jalur, ignore_changes desired_count)

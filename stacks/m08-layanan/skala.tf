# C.1 Auto scaling layanan stabil: kode menyatakan batas (1-skala_maks) dan target CPU, bukan jumlah task.

resource "aws_appautoscaling_target" "stabil" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ini.name}/${aws_ecs_service.api["stabil"].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = var.skala_maks
  tags               = { Name = "${local.awalan}-stabil", peran = "skala" }
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.awalan}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.stabil.service_namespace
  resource_id        = aws_appautoscaling_target.stabil.resource_id
  scalable_dimension = aws_appautoscaling_target.stabil.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.target_cpu
    scale_out_cooldown = 60
    scale_in_cooldown  = 120
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

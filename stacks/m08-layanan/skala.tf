# Auto scaling layanan stabil. Ikuti naskah Bagian C.1.

# TODO C.1  aws_appautoscaling_target.stabil (ecs:service:DesiredCount, min 1, max var.skala_maks) dan
#           aws_appautoscaling_policy.cpu (TargetTrackingScaling, ECSServiceAverageCPUUtilization,
#           target var.target_cpu, cooldown keluar 60 dan masuk 120)

# Modul 06 — log, alarm, dan dasbor sebagai kode. Ikuti naskah Bagian D.

# TODO D.1  aws_cloudwatch_log_group.api (local.log_group, retensi 1 hari). Ditulis di Bagian C.3,
#           karena server hijau merujuknya.
# TODO D.2  aws_cloudwatch_metric_alarm.latensi ("${local.awalan}-latensi-p95": AWS/ApplicationELB
#           TargetResponseTime, dimensi LoadBalancer = aws_lb.api.arn_suffix, p95, 60 dtk, 1 periode,
#           ambang var.ambang_latensi_detik, data hilang = notBreaching)
# TODO D.3  aws_cloudwatch_dashboard.api (local.awalan): permintaan, p95, target sehat, dan alarm

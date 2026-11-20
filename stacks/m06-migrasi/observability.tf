# Modul 06 — log, alarm, dan dasbor sebagai kode. Ikuti naskah Bagian D.

# D.1 Log group API (ditulis bersama C.3 karena server hijau merujuknya; role server tidak boleh membuatnya)
resource "aws_cloudwatch_log_group" "api" {
  name              = local.log_group
  retention_in_days = 1
  tags              = { Name = "${local.awalan}-log", peran = "log" }
}

# D.2 Alarm latensi dari SLO: p95 waktu respons target di ALB melewati ambang selama satu menit -> ALARM.
resource "aws_cloudwatch_metric_alarm" "latensi" {
  alarm_name          = "${local.awalan}-latensi-p95"
  alarm_description   = "p95 TargetResponseTime ALB koma-api di atas ${var.ambang_latensi_detik} detik selama 1 menit"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = aws_lb.api.arn_suffix }
  extended_statistic  = "p95"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.ambang_latensi_detik
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  tags                = { Name = "${local.awalan}-latensi-p95", peran = "alarm" }
}

# D.3 Dasbor: permintaan, p95, target sehat di hijau, dan status alarm
resource "aws_cloudwatch_dashboard" "api" {
  dashboard_name = local.awalan
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "Permintaan per menit"
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.api.arn_suffix]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "Waktu respons target p95 (detik)"
          region  = var.region
          stat    = "p95"
          period  = 60
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.api.arn_suffix]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Target sehat per versi"
          region  = var.region
          stat    = "Minimum"
          period  = 60
          metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.hijau.arn_suffix, "LoadBalancer", aws_lb.api.arn_suffix]]
        }
      },
      {
        type = "alarm", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Alarm"
          alarms = [aws_cloudwatch_metric_alarm.latensi.arn]
        }
      },
    ]
  })
}

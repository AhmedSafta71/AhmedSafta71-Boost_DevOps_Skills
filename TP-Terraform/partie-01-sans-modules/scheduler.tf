############################################################
# EventBridge Scheduler : stop 19h / start 9h (Europe/Paris)
############################################################
resource "aws_scheduler_schedule" "stop" {
  name        = "${local.prefix}_schedule_stop_ec2"
  description = "Arret des EC2 a 19h (Europe/Paris)"
  group_name  = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.stop_schedule_expression
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.scheduler.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ action = "stop" })

    retry_policy {
      maximum_retry_attempts = 2
    }
  }
}

resource "aws_scheduler_schedule" "start" {
  name        = "${local.prefix}_schedule_start_ec2"
  description = "Demarrage des EC2 a 9h (Europe/Paris)"
  group_name  = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.start_schedule_expression
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.scheduler.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ action = "start" })

    retry_policy {
      maximum_retry_attempts = 2
    }
  }
}

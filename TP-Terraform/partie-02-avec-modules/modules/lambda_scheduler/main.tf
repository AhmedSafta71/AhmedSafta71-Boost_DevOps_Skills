locals {
  function_name = "${var.prefix}_lambda_ec2_scheduler${var.suffix}"

  schedules = {
    start = {
      expression  = var.start_expression
      description = "Demarrage des EC2 a 9h (Europe/Paris) - modules_ref"
    }
    stop = {
      expression  = var.stop_expression
      description = "Arret des EC2 a 19h (Europe/Paris) - modules_ref"
    }
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_file = var.source_file
  output_path = "${var.build_dir}/ec2_scheduler${var.suffix}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.prefix}_loggroup_lambda_scheduler${var.suffix}" }
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  description      = "Start 9h / Stop 19h des EC2 du TP safta_ahmed (modules_ref)"
  role             = var.lambda_role_arn
  runtime          = "python3.12"
  handler          = "ec2_scheduler.handler"
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      INSTANCE_IDS = join(",", var.instance_ids)
    }
  }

  tags = { Name = local.function_name }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_scheduler_schedule" "this" {
  for_each = local.schedules

  name        = "${var.prefix}_schedule_${each.key}_ec2${var.suffix}"
  description = each.value.description
  group_name  = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = each.value.expression
  schedule_expression_timezone = var.timezone

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = var.scheduler_role_arn
    input    = jsonencode({ action = each.key })

    retry_policy {
      maximum_retry_attempts = 2
    }
  }
}

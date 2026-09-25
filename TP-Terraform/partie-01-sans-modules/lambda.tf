############################################################
# Lambda : arrêt 19h / démarrage 9h des EC2
############################################################
data "archive_file" "scheduler" {
  type        = "zip"
  source_file = "${path.module}/lambda/ec2_scheduler.py"
  output_path = "${path.module}/.build/ec2_scheduler.zip"
}

resource "aws_cloudwatch_log_group" "scheduler" {
  name              = "/aws/lambda/${local.prefix}_lambda_ec2_scheduler"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.prefix}_loggroup_lambda_scheduler" }
}

resource "aws_lambda_function" "scheduler" {
  function_name    = "${local.prefix}_lambda_ec2_scheduler"
  description      = "Start 9h / Stop 19h des EC2 du TP safta_ahmed"
  role             = data.aws_iam_role.lambda_scheduler_imported.arn
  runtime          = "python3.12"
  handler          = "ec2_scheduler.handler"
  filename         = data.archive_file.scheduler.output_path
  source_code_hash = data.archive_file.scheduler.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      INSTANCE_IDS = join(",", [aws_instance.docker.id, aws_instance.nodejs.id])
    }
  }

  tags = { Name = "${local.prefix}_lambda_ec2_scheduler" }

  depends_on = [aws_cloudwatch_log_group.scheduler]
  # depends_on = [aws_cloudwatch_log_group.scheduler, aws_iam_role_policy.lambda_scheduler]
}

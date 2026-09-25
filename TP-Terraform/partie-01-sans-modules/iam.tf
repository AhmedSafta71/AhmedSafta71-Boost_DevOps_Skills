############################################################
# IAM : tous les rôles et policies du TP
############################################################

# ==========================================================
# EC2 : rôle pour SSM + instance profile
# ==========================================================
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_instance_profile" "ssm" {
  name = var.instance_profile_name
}

resource "aws_iam_role" "ec2_ssm" {
  name               = "${local.prefix}_role_ec2_ssm"
  description        = "Role EC2 SSM - TP safta_ahmed"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

 
}

# Problem  in access we  do not have a permission to make an attachement api call 
# resource "aws_iam_role_policy_attachment" "ec2_ssm" {
#   role       = aws_iam_role.ec2_ssm.name
#   policy_arn = var.ec2_ssm_policy_arn
# }

# resource "aws_iam_instance_profile" "ec2_ssm" {
#   name = "${local.prefix}_instance_profile_ssm"
#   role = aws_iam_role.ec2_ssm.name

#   # tags = { Name = "${local.prefix}_instance_profile_ssm" }
# }

# ==========================================================
# Lambda : start/stop UNIQUEMENT sur MES 2 instances
# ==========================================================
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_scheduler" {
  name               = "${local.prefix}_role_lambda_scheduler"
  description        = "Role Lambda start stop EC2 - TP safta_ahmed"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  # tags = { Name = "${local.prefix}_role_lambda_scheduler" }
}

# data "aws_iam_policy_document" "lambda_scheduler" {
#   statement {
#     sid       = "StartStopOwnInstancesOnly"
#     actions   = ["ec2:StartInstances", "ec2:StopInstances"]
#     resources = [aws_instance.docker.arn, aws_instance.nodejs.arn]
#   }

#   statement {
#     sid       = "WriteOwnLogGroupOnly"
#     actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
#     resources = ["${aws_cloudwatch_log_group.scheduler.arn}:*"]
#   }
# }

# resource "aws_iam_role_policy" "lambda_scheduler" {
#   name   = "${local.prefix}_policy_lambda_scheduler"
#   role   = aws_iam_role.lambda_scheduler.id
#   policy = data.aws_iam_policy_document.lambda_scheduler.json
# }

data "aws_iam_role" "lambda_scheduler_imported" {
  name = "tech_mind_safta_ahmed_lambda_instance_autoControl-role-mwanid2l"
}

# ==========================================================
# EventBridge Scheduler : invoquer UNIQUEMENT ma Lambda
# ==========================================================
data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.prefix}_role_eventbridge_scheduler"
  description        = "Role EventBridge Scheduler - TP safta_ahmed"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json

}

data "aws_iam_policy_document" "scheduler_invoke" {
  statement {
    sid       = "InvokeOwnLambdaOnly"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.scheduler.arn, "${aws_lambda_function.scheduler.arn}:*"]
  }
}

# resource "aws_iam_role_policy" "scheduler" {
#   name   = "${local.prefix}_policy_eventbridge_scheduler"
#   role   = aws_iam_role.scheduler.id
#   policy = data.aws_iam_policy_document.scheduler_invoke.json
# }

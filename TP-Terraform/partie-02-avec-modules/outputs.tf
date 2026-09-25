output "aws_region" {
  value = var.aws_region
}

output "admin_ssh_cidr" {
  description = "IP autorisée en SSH sur le serveur public"
  value       = local.admin_ssh_cidr
}

output "public_instance_id" {
  value = module.ec2_docker.id
}

output "public_instance_public_ip" {
  description = "Change après un stop/start (faire terraform apply -refresh-only)"
  value       = module.ec2_docker.public_ip
}

output "private_instance_id" {
  value = module.ec2_nodejs.id
}

output "private_instance_private_ip" {
  value = module.ec2_nodejs.private_ip
}

output "s3_bucket_names" {
  value = [for b in module.s3 : b.bucket]
}

output "lambda_function_name" {
  value = module.lambda_scheduler.function_name
}

output "iam_consumed" {
  description = "Rôles IAM existants consommés (aucun créé)"
  value = {
    instance_profile = data.aws_iam_instance_profile.ssm.name
    lambda_role      = data.aws_iam_role.lambda_scheduler.arn
    scheduler_role   = data.aws_iam_role.scheduler.arn
  }
}


output "ssm_commands" {
  value = {
    session_public  = "aws ssm start-session --target ${module.ec2_docker.id} --region ${var.aws_region}"
    session_private = "aws ssm start-session --target ${module.ec2_nodejs.id} --region ${var.aws_region}"
    test_stop       = "aws lambda invoke --function-name ${module.lambda_scheduler.function_name} --cli-binary-format raw-in-base64-out --payload '{\"action\":\"stop\"}' --region ${var.aws_region} /dev/stdout"
    test_start      = "aws lambda invoke --function-name ${module.lambda_scheduler.function_name} --cli-binary-format raw-in-base64-out --payload '{\"action\":\"start\"}' --region ${var.aws_region} /dev/stdout"
  }
}

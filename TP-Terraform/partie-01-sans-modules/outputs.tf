############################################################
# Outputs
############################################################

output "aws_region" {
  value = var.aws_region
}

output "admin_ssh_cidr" {
  description = "IP autorisée en SSH sur le serveur public"
  value       = local.admin_ssh_cidr
}

output "public_instance_id" {
  value = aws_instance.docker.id
}

output "public_instance_public_ip" {
  description = "Change après un stop/start (faire terraform apply -refresh-only)"
  value       = aws_instance.docker.public_ip
}

output "private_instance_id" {
  value = aws_instance.nodejs.id
}

output "private_instance_private_ip" {
  value = aws_instance.nodejs.private_ip
}

output "s3_bucket_names" {
  value = [for b in aws_s3_bucket.this : b.bucket]
}

output "lambda_function_name" {
  value = aws_lambda_function.scheduler.function_name
}

# output "ssh_config" {
#   description = "Bloc à coller dans ~/.ssh/config"
#   value       = <<-EOT
#     # ===== TP tech_mind safta_ahmed : SSH classique (bastion / ProxyJump) =====
#     Host safta-public
#       HostName ${aws_instance.docker.public_ip}
#       User ec2-user
#       IdentityFile ${local.ssh_key_path}
#       IdentitiesOnly yes

#     Host safta-private
#       HostName ${aws_instance.nodejs.private_ip}
#       User ec2-user
#       IdentityFile ${local.ssh_key_path}
#       IdentitiesOnly yes
#       ProxyJump safta-public

#     # ===== Variante recommandée : SSH tunnelé dans SSM (aucun port 22 exposé) =====
#     Host safta-public-ssm
#       HostName ${aws_instance.docker.id}
#       User ec2-user
#       IdentityFile ${local.ssh_key_path}
#       IdentitiesOnly yes
#       ProxyCommand aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region ${var.aws_region}

#     Host safta-private-ssm
#       HostName ${aws_instance.nodejs.id}
#       User ec2-user
#       IdentityFile ${local.ssh_key_path}
#       IdentitiesOnly yes
#       ProxyCommand aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region ${var.aws_region}
#   EOT
# }

output "ssm_commands" {
  value = {
    session_public  = "aws ssm start-session --target ${aws_instance.docker.id} --region ${var.aws_region}"
    session_private = "aws ssm start-session --target ${aws_instance.nodejs.id} --region ${var.aws_region}"
    test_stop       = "aws lambda invoke --function-name ${aws_lambda_function.scheduler.function_name} --cli-binary-format raw-in-base64-out --payload '{\"action\":\"stop\"}' --region ${var.aws_region} /dev/stdout"
    test_start      = "aws lambda invoke --function-name ${aws_lambda_function.scheduler.function_name} --cli-binary-format raw-in-base64-out --payload '{\"action\":\"start\"}' --region ${var.aws_region} /dev/stdout"
  }
}

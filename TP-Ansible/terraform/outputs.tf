output "aws_region" {
  value = var.aws_region
}

output "admin_ssh_cidr" {
  description = "IP autorisée en SSH sur le serveur public"
  value       = local.admin_ssh_cidr
}

output "front1_instance_id" {
  value = module.front1.id
}

output "front1_public_ip" {
  description = "Change après un stop/start (faire terraform apply -refresh-only)"
  value       = module.front1.public_ip
}

output "front2_instance_id" {
  value = module.front2.id
}

output "front2_public_ip" {
  description = "Change après un stop/start (faire terraform apply -refresh-only)"
  value       = module.front2.public_ip
}

output "private_instance_id" {
  value = module.db.id
}

output "private_instance_private_ip" {
  value = module.db.private_ip
}



output "iam_consumed" {
  description = "Rôles IAM existants consommés (aucun créé)"
  value = {
    instance_profile = data.aws_iam_instance_profile.ssm.name
  }
}


output "ssm_commands" {
  value = {
    session_public  = "aws ssm start-session --target ${module.front1.id} --region ${var.aws_region}"
    session_public  = "aws ssm start-session --target ${module.front2.id} --region ${var.aws_region}"
    session_private = "aws ssm start-session --target ${module.db.id} --region ${var.aws_region}"
  }
}


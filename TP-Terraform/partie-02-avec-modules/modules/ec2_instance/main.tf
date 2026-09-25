resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obligatoire
    http_put_response_hop_limit = var.http_put_response_hop_limit
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  volume_tags = merge(var.default_tags, { Name = var.ebs_name })

  tags = {
    Name = var.name
    Role = var.role_tag
  }

  lifecycle {
    ignore_changes = [ami] # évite de recréer l'instance à chaque nouvelle AMI
  }
}

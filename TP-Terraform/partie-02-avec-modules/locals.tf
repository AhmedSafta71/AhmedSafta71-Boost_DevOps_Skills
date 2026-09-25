locals {
  prefix         = var.name_prefix                           # tech_mind_iac_safta_ahmed
  suffix         = var.name_suffix                           # _modules_ref
  bucket_prefix  = replace(lower(var.name_prefix), "_", "-") # S3 interdit les "_"
  bucket_suffix  = replace(lower(var.name_suffix), "_", "-") # -modules-ref
  admin_ssh_cidr = var.allowed_ssh_cidr != "" ? var.allowed_ssh_cidr : "${chomp(data.http.my_public_ip.response_body)}/32"
  ssh_key_path   = trimsuffix(var.ssh_public_key_path, ".pub")
}

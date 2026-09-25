variable "name" {
  description = "Tag Name de l'instance"
  type        = string
}

variable "ebs_name" {
  description = "Tag Name du volume racine"
  type        = string
}

variable "role_tag" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}

variable "key_name" {
  type = string
}

variable "iam_instance_profile" {
  description = "Instance profile EXISTANT (non créé par ce module)"
  type        = string
}

variable "user_data" {
  type = string
}

variable "http_put_response_hop_limit" {
  type    = number
  default = 1
}

variable "root_volume_size" {
  type = number
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

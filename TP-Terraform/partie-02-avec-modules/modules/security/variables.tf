variable "prefix" {
  type = string
}

variable "suffix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "admin_ssh_cidr" {
  description = "CIDR autorisé en SSH sur le serveur public"
  type        = string
}

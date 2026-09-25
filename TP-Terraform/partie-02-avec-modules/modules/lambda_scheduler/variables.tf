variable "prefix" {
  type = string
}

variable "suffix" {
  type = string
}

variable "source_file" {
  description = "Chemin du code Python de la Lambda"
  type        = string
}

variable "build_dir" {
  description = "Dossier où générer le zip"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN du rôle Lambda EXISTANT (non créé par ce module)"
  type        = string
}

variable "scheduler_role_arn" {
  description = "ARN du rôle EventBridge Scheduler EXISTANT (non créé par ce module)"
  type        = string
}

variable "instance_ids" {
  type = list(string)
}

variable "log_retention_days" {
  type = number
}

variable "start_expression" {
  type = string
}

variable "stop_expression" {
  type = string
}

variable "timezone" {
  type = string
}

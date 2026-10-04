variable "bucket_name" {
  type = string
}

variable "name_tag" {
  type = string
}

variable "force_destroy" {
  description = "TP : permet le destroy même si le bucket contient des objets"
  type        = bool
  default     = true
}

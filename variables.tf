variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo del proyecto"
  type        = string
  default     = "banking-tx-processor"
}

variable "bucket_name" {
  description = "OpenTofu Practice"
  type        = string
  default     = "banking-tx-processor-emiliano-corona"  # <-- cambia esto
}
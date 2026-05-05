variable "function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "filename" {
  description = "Ruta al ZIP de la Lambda"
  type        = string
}

variable "handler" {
  description = "Handler de la Lambda (archivo.función)"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Runtime de Python"
  type        = string
  default     = "python3.12"
}

variable "role_arn" {
  description = "ARN del IAM role para la Lambda"
  type        = string
}

variable "environment_variables" {
  description = "Variables de entorno para la Lambda"
  type        = map(string)
  default     = {}
}
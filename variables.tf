variable "profile_name" {
  description = "AWS CLI profile name"
  type        = string
  default     = "acc_3_admin"
}

variable "main_region" {
  description = "Main region"
  type        = string
  default     = "us-east-1"
}

variable "base_name" {
  description = "Base name for all resources"
  type        = string
  default     = "bsd-uchicago-312"
}

variable "main_tags" {
  description = "Tags to apply to resources created"
  type        = map(string)
  default = {
    TechnicalContact = "DevOps"
    Environment = "dev"
    ControlledBy = "terraform"
  }
}  

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default     = "bsdUChicagoGreeting"
}


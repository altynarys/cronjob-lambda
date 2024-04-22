# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

terraform {
  backend "s3" {
    bucket         = "bsd-uchicago-312-terraform-state-bucket"
    key            = "bsd-uchicago/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bsd-uchicago-312-terraform-lock-table"
  }
}
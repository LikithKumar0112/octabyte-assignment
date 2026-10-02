terraform {
  backend "s3" {
    bucket         = "octabyte-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "octabyte-terraform-locks"
    encrypt        = true
  }
}
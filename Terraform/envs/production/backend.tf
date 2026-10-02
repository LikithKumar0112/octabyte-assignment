terraform {
  backend "s3" {
    bucket       = "octabyte-tfstate"
    key          = "production/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
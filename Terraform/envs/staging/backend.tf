terraform {
  backend "s3" {
    bucket       = "octabyte-tfstate"
    key          = "staging/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
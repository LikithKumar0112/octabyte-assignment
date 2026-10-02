terraform {
    backend "s3" {
        bucket = "octabyte-tfstate" 
        key = "shared/terraform.tfstate"
        region = "ap-south-1"
        encrypt = true
        use_lockfile = true
    }
}
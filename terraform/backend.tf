terraform {
  backend "s3" {
    bucket       = "honeypot-tfstate-466646844197"
    key          = "honeypot/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
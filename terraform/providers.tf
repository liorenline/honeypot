provider "aws" {
  region              = var.region
  allowed_account_ids = ["466646844197"]

  default_tags {
    tags = {
      Project   = "honeypot"
      ManagedBy = "terraform"
    }
  }
}
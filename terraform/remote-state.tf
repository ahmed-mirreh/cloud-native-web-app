terraform {
  backend "s3" {
    bucket       = "nba-higher-lower-game-terraform-state"
    key          = "project-1/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
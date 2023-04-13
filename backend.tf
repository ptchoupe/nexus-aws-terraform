terraform {
  backend "s3" {
    bucket = "terraformstatefile01"
    key    = "nexus_state"
    region = "us-east-1"
  }
}
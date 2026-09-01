provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      project = "EKS Cluster Setup and Three-Tier Deployment"
    }
  }
}

terraform {
  required_version = ">= 1.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.2"
    }
  }
}


terraform {
  backend "s3" {
    bucket  = "state-bucket-216989097838"
    key     = "eks-three-tier/eksinfra/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
     # assume_role {
     #   ## The ARN of the role in Account B to assume. i.e when you have multiple AWS accounts and you want to manage resources in another account, you can use the assume_role block to specify the ARN of the role in that account that you want to assume.
     #   role_arn = "arn:aws:iam::01234567890:role/role_in_account_b"
     # }
  }
}


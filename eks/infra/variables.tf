variable "environment" {
  description = "The environment for the infrastructure (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

}

variable "project" {
  description = "The project name"
  type        = string
  default     = "eks-three-tier-end-to-end"

}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "eks-vpc"

}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for the subnets"
  type        = map(list(string))
  default = {
    private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  }

}





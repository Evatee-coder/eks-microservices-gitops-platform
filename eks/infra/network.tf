module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "${var.project}-${var.environment}-${var.vpc_name}"
  cidr = var.vpc_cidr

  # for two azs
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = var.subnet_cidrs["private_subnets"]
  public_subnets  = [var.subnet_cidrs["public_subnets"][0], var.subnet_cidrs["public_subnets"][1]]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  # EKS nodes generally need a NAT gateway (or a public IP and an Internet Gateway) to join and operate within a private subnet. 
  # NAT gateway is required to allow pods get image (private or public) from internet.
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags for EKS cluster subnet discovery

  # The tags below will allow kubernetes cluster to find those public subnets to create those load balancer 
  public_subnet_tags = {
    "kubernetes.io/cluster/eks-three-tier-end-to-end" = "shared"
    "kubernetes.io/role/elb"                          = "1"
  }

  # Required tags for EKS cluster subnet discovery
  private_subnet_tags = {
    "kubernetes.io/cluster/eks-three-tier-end-to-end" = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
  }

}
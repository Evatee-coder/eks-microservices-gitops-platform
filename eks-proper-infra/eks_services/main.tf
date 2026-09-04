# data "aws_eks_cluster" "eks" {
#   name = module.eks[0].cluster_name
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks[0].cluster_name
# }

# # Kubernetes provider configuration for EKS cluster. 
# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       module.eks.cluster_name,
#       "--region",
#       "us-east-1"
#     ]
#   }
# }

# provider "helm" {
#   kubernetes = {
#     host                   = module.eks[0].cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)

#     exec = {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         module.eks[0].cluster_name,
#         "--region",
#         "us-east-1"
#       ]
#     }
#   }
# }



# # IAM role and policy for AWS Load Balancer Controller 

# # Helm Chart deployment for AWS Load Balancer Controller

# # Install AWS Load Balancer Controller using Helm 
# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.8.1"

#   set = [
#     {
#       name  = "clusterName"
#       value = module.eks[0].cluster_name
#     },
#     {
#       name  = "serviceAccount.create"
#       value = "true"
#     },
#     {
#       name  = "serviceAccount.name"
#       value = "aws-load-balancer-controller"
#     },
#     {
#       name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#       value = aws_iam_role.aws_load_balancer_controller.arn
#     },
#     {
#       name  = "region"
#       value = "us-east-1"
#     },
#     {
#       name  = "vpcId"
#       value = module.vpc.vpc_id
#     },
#   ]

#   depends_on = [
#     aws_iam_role_policy_attachment.aws_load_balancer_controller,
#     module.eks
#   ]
# }

# Service account for AWS Load Balancer Controller

# OIDC







# Helm provider moved to providers.tf to avoid duplication

# IAM role and policy for AWS Load Balancer Controller 

# Helm Chart deployment for AWS Load Balancer Controller

# Install AWS Load Balancer Controller using Helm 
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.aws_load_balancer_controller.arn
    },
    {
      name  = "region"
      value = "us-east-1"
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    },
  ]

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
    module.eks
  ]
}

# Service account for AWS Load Balancer Controller

# OIDC
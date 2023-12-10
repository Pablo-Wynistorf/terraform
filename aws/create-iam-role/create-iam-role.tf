provider "aws" {
  region = var.var-region
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

data "aws_caller_identity" "current" {}

output "variable-test" {
  value = "Test-Variable: ${data.aws_caller_identity.current.account_id} "
}

resource "aws_iam_role" "createEKSClusterRole" {
  name = "eksClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "createEKSNodeRole" {
  name = "eksNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_AmazonEKSClusterPolicyCluster" {
  role       = aws_iam_role.createEKSClusterRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role_policy_attachment" "attach_AmazonEKSClusterPolicyNode" {
  role       = aws_iam_role.createEKSNodeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}



resource "aws_iam_role_policy_attachment" "attach_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.createEKSNodeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}



resource "aws_iam_role_policy_attachment" "attach_AmazonEC2ContainerRegistryReadOnlyPolicy" {
  role       = aws_iam_role.createEKSNodeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


provider "aws" {
  region = var.cluster-name
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

variable "cluster-name" {
  description = "Define the name of the cluster"
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

resource "aws_iam_role_policy_attachment" "attach_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.createEKSNodeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "eks-cluster" {
  name = var.cluster-name
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eksClusterRole"
  vpc_config {
    subnet_ids = [aws_subnet.eks-a-1.id, aws_subnet.eks-b-1.id, aws_subnet.eks-c-1.id]
    security_group_ids = [aws_security_group.https.id]
  }
}

resource "aws_placement_group" "eks-cluster-placement_group" {
  name     = "${var.cluster-name}-placement-group"
  strategy = "spread"
}

resource "aws_eks_node_group" "eks-cluster-node-group" {
  cluster_name = aws_eks_cluster.eks-cluster.name
  node_group_name = "${var.cluster-name}-cluster-node-group"
  subnet_ids = [aws_subnet.eks-a-1.id, aws_subnet.eks-b-1.id, aws_subnet.eks-c-1.id]
  node_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eksNodeRole"
  scaling_config {
    desired_size = 6
    max_size = 6
    min_size = 6
  }
  disk_size = 20
  instance_types = ["t3.medium"]
  remote_access {
    ec2_ssh_key = "eks-nodes"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks-cluster.name
  addon_name = "kube-proxy"
}



resource "aws_eks_addon" "amazon_vpc_cni" {
  cluster_name = aws_eks_cluster.eks-cluster.name
  addon_name = "vpc-cni"
}


resource "null_resource" "send-ps-command" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.var-region} update-kubeconfig --name ${aws_eks_cluster.eks-cluster.name}"
  }
}
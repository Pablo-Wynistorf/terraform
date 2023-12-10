provider "aws" {
  region = "${var.var-region}"
}

variable "addons-installed" {
  description = "Do you have AWS Cli and eksctl installed? If not, do that first, otherwise the script won't work properly."
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}


data "aws_caller_identity" "current" {}


variable "var-cluster-name" {
  description = "Enter the name of your existing cluster"
}

data "aws_eks_cluster" "cluster-name" {
  name = var.var-cluster-name
}



resource "aws_iam_role" "AmazonEKS_EFS_CSI_DriverRole" {
  name = "AmazonEKS_EFS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster-name.identity[0].oidc[0].issuer, "https://", "")}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "${replace(data.aws_eks_cluster.cluster-name.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:efs-csi-*"
                    "${replace(data.aws_eks_cluster.cluster-name.identity[0].oidc[0].issuer, "https://", "")}:aud": "sts.amazonaws.com",
                }
            }
        }
    ]
})
}



resource "aws_iam_role_policy_attachment" "AmazonEFSCSIDriverPolicy_attachment" {
  role       = aws_iam_role.AmazonEKS_EFS_CSI_DriverRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}


resource "aws_eks_addon" "aws-efs-csi-driver" {
  cluster_name = data.aws_eks_cluster.cluster-name.name
  addon_name = "aws-efs-csi-driver"
  service_account_role_arn= "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEKS_EFS_CSI_DriverRole"
}


resource "null_resource" "add-oidc-provider" {
  provisioner "local-exec" {
    command = "eksctl utils associate-iam-oidc-provider --region ${var.var-region} --cluster ${var.var-cluster-name} --approve"
  }
}


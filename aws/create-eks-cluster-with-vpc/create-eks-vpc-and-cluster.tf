provider "aws" {
  region = var.var-region
}

variable "addons-installed" {
  description = "Do you have AWS Cli and kubectl installed? If not, do that first, otherwise the script won't work properly."
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

variable "cluster-name" {
  description = "Define the name of the cluster"
}

variable "kubernetes-version" {
  description = "What kubernetes version do you wanna use?"
}

variable "vpc-name" {
  description = "Define the name of the vpc"
}

variable "subnet-name" {
  description = "Define the name of the subnets (Format:___-az-subnet-nr.)"
}

variable "node-instancetype" {
  description = "Define the instancetype for your nodes (Example: t3.medium)"
}

variable "node-instancediskspace" {
  description = "Define the amount of storage per node (in GB)"
}

variable "node-count-des" {
  description = "Define the desired number of nodes you want in your cluster"
}

variable "node-count-max" {
  description = "Define the maximum number of nodes you want in your cluster"
}

variable "node-count-min" {
  description = "Define the minimum number of nodes you want in your cluster"
}



# Create a VPC
resource "aws_vpc" "eks-vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.vpc-name}"
  }
}
 
#create ssh key pair
resource "aws_key_pair" "ssh-key" {
  key_name   = "eks-nodes"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#download key pair
resource "local_file" "ssh-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "eks-nodes.pem"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.eks-vpc.id
}

# Create a NAT-Gateway EIP
resource "aws_eip" "nat-gateway-eip" {
}


# Create a route table to internet gatway
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.eks-vpc.id
  route {
cidr_block = "0.0.0.0/0"
gateway_id = "${aws_internet_gateway.internet-gateway.id}"
}
}



# Create a public subnet-a
resource "aws_subnet" "eks-a-1" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "${var.var-region}a"
  map_public_ip_on_launch = true
    tags = {
    Name = "${var.subnet-name}-public-a-1"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/role/elb" = "1"
  }
}
# Create a private subnet-a
resource "aws_subnet" "eks-a-2" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.8.0/21"
  availability_zone = "${var.var-region}a"
    tags = {
    Name = "${var.subnet-name}-app-a-2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
# Create a private subnet-a
resource "aws_subnet" "eks-a-3" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.64.0/18"
  availability_zone = "${var.var-region}a"
    tags = {
    Name = "${var.subnet-name}-eks-a-3"
  }
}
# Create a public subnet-b
resource "aws_subnet" "eks-b-1" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.var-region}b"
    tags = {
    Name = "${var.subnet-name}-public-b-1"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/role/elb" = "1"
  }
}
# Create a private subnet-b
resource "aws_subnet" "eks-b-2" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.16.0/21"
  availability_zone = "${var.var-region}b"
    tags = {
    Name = "${var.subnet-name}-app-b-2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
# Create a private subnet-b
resource "aws_subnet" "eks-b-3" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.128.0/18"
  availability_zone = "${var.var-region}b"
    tags = {
    Name = "${var.subnet-name}-eks-b-3"
  }
}
# Create a public subnet-c
resource "aws_subnet" "eks-c-1" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.var-region}c"
    tags = {
    Name = "${var.subnet-name}-public-c-1"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/role/elb" = "1"
  }
}
# Create a private subnet-c
resource "aws_subnet" "eks-c-2" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.24.0/21"
  availability_zone = "${var.var-region}c"
    tags = {
    Name = "${var.subnet-name}-app-c-2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
# Create a private subnet-c
resource "aws_subnet" "eks-c-3" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.1.192.0/18"
  availability_zone = "${var.var-region}c"
    tags = {
    Name = "${var.subnet-name}-eks-c-3"
  }
}

# Create a NAT-Gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-gateway-eip.id
  subnet_id     = aws_subnet.eks-a-1.id
}


resource "aws_db_subnet_group" "eks_db_subnet_group" {
  name       = "app-db-subnet-group"
  description = "${var.cluster-name} DB Subnet Group"
  subnet_ids = [aws_subnet.eks-a-2.id, aws_subnet.eks-b-2.id, aws_subnet.eks-c-2.id,]
}


# Create a route table to NAT-Gatway
resource "aws_route_table" "nat-gatway-rt" {
  vpc_id = aws_vpc.eks-vpc.id
}
resource "aws_route" "nat-gatway-route" {
  route_table_id         = aws_route_table.nat-gatway-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway.id
}

resource "aws_main_route_table_association" "main_route_table_association" {
  vpc_id = aws_vpc.eks-vpc.id
  route_table_id = aws_route_table.main_route_table.id
}

# Create route table assosiation
resource "aws_route_table_association" "Connect-eks-a-1" {
  subnet_id = "${aws_subnet.eks-a-1.id}"
  route_table_id = "${aws_route_table.main_route_table.id}"
}

resource "aws_route_table_association" "Connect-eks-a-2" {
  subnet_id = "${aws_subnet.eks-a-2.id}"
  route_table_id = "${aws_route_table.nat-gatway-rt.id}"
}

resource "aws_route_table_association" "Connect-eks-a-3" {
  subnet_id = "${aws_subnet.eks-a-3.id}"
  route_table_id = "${aws_route_table.nat-gatway-rt.id}"
}

resource "aws_route_table_association" "Connect-eks-b-1" {
  subnet_id = "${aws_subnet.eks-b-1.id}"
  route_table_id = "${aws_route_table.main_route_table.id}"
}

resource "aws_route_table_association" "Connect-eks-b-2" {
  subnet_id = "${aws_subnet.eks-b-2.id}"
  route_table_id = "${aws_route_table.nat-gatway-rt.id}"
}

resource "aws_route_table_association" "Connect-eks-b-3" {
  subnet_id = "${aws_subnet.eks-b-3.id}"
  route_table_id = "${aws_route_table.nat-gatway-rt.id}"
}

resource "aws_route_table_association" "Connect-eks-c-1" {
  subnet_id = "${aws_subnet.eks-c-1.id}"
  route_table_id = "${aws_route_table.main_route_table.id}"
}

resource "aws_route_table_association" "Connect-eks-c-2" {
  subnet_id = "${aws_subnet.eks-c-2.id}"
  route_table_id = "${aws_route_table.nat-gatway-rt.id}"
}

resource "aws_route_table_association" "Connect-eks-c-3" {
  subnet_id = "${aws_subnet.eks-c-3.id}"
  route_table_id = "${aws_route_table.nat-gatway-rt.id}"
}


# Create a security group
resource "aws_security_group" "SSH" {
  name        = "SSH"
  description = "SSH Port 22 Open"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "SSH"
  }
}
#Create a security group
resource "aws_security_group" "http" {
  name        = "HTTP"
  description = "HTTP Port 80 Open"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "HTTP"
  }
}
#Create a security group
resource "aws_security_group" "https" {
  name        = "HTTPS"
  description = "HTTPS Port 443 Open"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "HTTPS"
  }
}
#Create a security group
resource "aws_security_group" "http-old" {
  name        = "HTTP-OLD"
  description = "HTTP Port 8080 Open"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "HTTP-OLD"
  }
}
#Create a security group
resource "aws_security_group" "no-ingress" {
  name        = "NO-INGRESS"
  description = "All Ports closed"
  vpc_id      = aws_vpc.eks-vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "NO-INGRESS"
  }
}
#Create a security group
resource "aws_security_group" "open-ingress-all-protocols" {
  name        = "OPEN-INGRESS-ALL-PROTOCOLS"
  description = "All Ports open"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "OPEN-INGRESS-ALL-PROTOCOLS"
  }
}
#Create a security group
resource "aws_security_group" "open-ingress-tcp" {
  name        = "OPEN-INGRESS-TCP"
  description = "All Ports open for TCP"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "OPEN-INGRESS-TCP"
  }
}
#Create a security group
resource "aws_security_group" "open-ingress-udp" {
  name        = "OPEN-INGRESS-UDP"
  description = "All Ports open for UDP"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "OPEN-INGRESS-UDP"
  }
}
#Create a security group
resource "aws_security_group" "loadbalancer" {
  name        = "LOADBALANCER-HTTP-HTTPS"
  description = "Application Loadbalancer Port 80 and 443 open"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "LOADBALANCER-HTTP-HTTPS"
  }
}
#Create a security group
resource "aws_security_group" "http-by-loadbalancer" {
  name        = "HTTP-BY-LOADBALANCER"
  description = "Allows connections from the Securitygroup of the Loadbalancer"
  vpc_id      = aws_vpc.eks-vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.loadbalancer.id}"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "udp"
    security_groups = ["${aws_security_group.loadbalancer.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "HTTP-BY-LOADBALANCER"
  }
}
#Create a security group
resource "aws_security_group" "db-sg-db-site" {
  name        = "DB-SG-DB-SITE"
  description = "Allows traffik on tcp port 3306 by security group"
  vpc_id      = "${aws_vpc.eks-vpc.id}"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${aws_security_group.db-sg-ec2-site.id}"]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "udp"
    security_groups = ["${aws_security_group.db-sg-ec2-site.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "DB-SG-DB-SITE"
  }
}
#Create a security group
resource "aws_security_group" "db-sg-ec2-site" {
  name        = "DB-SG-EC2-SITE"
  description = "Allows traffik on tcp port 3306 by security group"
  vpc_id      = "${aws_vpc.eks-vpc.id}"
    tags = {
    Name = "DB-SG-EC2-SITE"
  }
}
#Create a security group
resource "aws_security_group" "open-ingress-by-sg-ingress-site" {
  name        = "OPEN-INGRESS-BY-SG--INGRESS-SITE"
  description = "Allows all connections from selected security group"
  vpc_id      = "${aws_vpc.eks-vpc.id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.open-ingress-by-sg-connect-site.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "OPEN-INGRESS-BY-SG--INGRESS-SITE"
  }
}
#Create a security group
resource "aws_security_group" "open-ingress-by-sg-connect-site" {
  name        = "OPEN-INGRESS-BY-SG--CONNECT-SITE"
  description = "Allows all connections from selected security group"
  vpc_id      = "${aws_vpc.eks-vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "OPEN-INGRESS-BY-SG--CONNECT-SITE"
  }
}

#Create a security group
resource "aws_security_group" "efs-access--efs-site" {
  name        = "EFS-ACCESS--EFS-SITE"
  description = "Allows efs connections from selected security group"
  vpc_id      = "${aws_vpc.eks-vpc.id}"
  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    security_groups = ["${aws_security_group.efs-access--connect-site.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "EFS-ACCESS--EFS-SITE"
  }
}
#Create a security group
resource "aws_security_group" "efs-access--connect-site" {
  name        = "EFS-ACCESS--CONNECT-SITE"
  description = "Allows efs connections from selected security group"
  vpc_id      = "${aws_vpc.eks-vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "EFS-ACCESS--CONNECT-SITE"
  }
}


#Create EKS Clusterrole
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

resource "aws_iam_role_policy_attachment" "attach_EC2_SSM_POLICY" {
  role       = aws_iam_role.createEKSNodeRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
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

resource "aws_placement_group" "eks-cluster-placement_group" {
  name     = "${var.cluster-name}-placement-group"
  strategy = "spread"
}


resource "aws_eks_cluster" "eks-cluster" {
  name = var.cluster-name
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eksClusterRole"
  version = var.kubernetes-version
  vpc_config {
    subnet_ids = [aws_subnet.eks-a-1.id, aws_subnet.eks-b-1.id, aws_subnet.eks-c-1.id]
    security_group_ids = [aws_security_group.https.id]
    public_access_cidrs = ["0.0.0.0/0"]
    endpoint_private_access = true
    endpoint_public_access  = true
  }
}



resource "aws_eks_node_group" "eks-cluster-node-group" {
  cluster_name = aws_eks_cluster.eks-cluster.name
  node_group_name = "${var.cluster-name}-node-group"
  subnet_ids = [aws_subnet.eks-a-3.id, aws_subnet.eks-b-3.id, aws_subnet.eks-c-3.id,]
  node_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eksNodeRole"
  scaling_config {
    desired_size = "${var.node-count-des}"
    max_size = "${var.node-count-max}"
    min_size = "${var.node-count-min}"
  }
  disk_size = "${var.node-instancediskspace}"
  instance_types = ["${var.node-instancetype}"]
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
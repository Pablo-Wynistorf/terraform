provider "aws" {
  region = var.var-region
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

variable "vpc-name" {
  description = "Enter the VPC name"
}

variable "subnet-name" {
  description = "Enter the subnet nameconcept (___-AZ-SUBNET-NR.)"
}

# Create a VPC
resource "aws_vpc" "ecs-vpc" {
  cidr_block = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.vpc-name}"
  }
}
 
#create ssh key pair
resource "aws_key_pair" "ssh-key" {
  key_name   = "ecs-nodes"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#download key pair
resource "local_file" "ssh-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "ecs-nodes.pem"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.ecs-vpc.id
}

# Create a NAT-Gateway EIP
resource "aws_eip" "nat-gateway-eip" {
}


# Create a route table to internet gatway
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.ecs-vpc.id
  route {
cidr_block = "0.0.0.0/0"
gateway_id = "${aws_internet_gateway.internet-gateway.id}"
}
}



# Create a public subnet-a
resource "aws_subnet" "eks-a-1" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.1.0/24"
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
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.2.0/24"
  availability_zone = "${var.var-region}a"
    tags = {
    Name = "${var.subnet-name}-nodes-a-2"
  }
}
# Create a private subnet-a
resource "aws_subnet" "eks-a-3" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.3.0/24"
  availability_zone = "${var.var-region}a"
    tags = {
    Name = "${var.subnet-name}-app-a-3"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
# Create a public subnet-b
resource "aws_subnet" "eks-b-1" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.4.0/24"
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
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.5.0/24"
  availability_zone = "${var.var-region}b"
    tags = {
    Name = "${var.subnet-name}-nodes-b-2"
  }
}
# Create a private subnet-b
resource "aws_subnet" "eks-b-3" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.6.0/24"
  availability_zone = "${var.var-region}b"
    tags = {
    Name = "${var.subnet-name}-app-b-3"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
# Create a public subnet-c
resource "aws_subnet" "eks-c-1" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.7.0/24"
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
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.8.0/24"
  availability_zone = "${var.var-region}c"
    tags = {
    Name = "${var.subnet-name}-nodes-c-2"
  }
}
# Create a private subnet-c
resource "aws_subnet" "eks-c-3" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.2.9.0/24"
  availability_zone = "${var.var-region}c"
    tags = {
    Name = "${var.subnet-name}-app-c-3"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Create a NAT-Gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-gateway-eip.id
  subnet_id     = aws_subnet.eks-a-1.id
}



# Create a route table to NAT-Gatway
resource "aws_route_table" "nat-gatway-rt" {
  vpc_id = aws_vpc.ecs-vpc.id
}
resource "aws_route" "nat-gatway-route" {
  route_table_id         = aws_route_table.nat-gatway-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway.id
}

resource "aws_main_route_table_association" "main_route_table_association" {
  vpc_id = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = aws_vpc.ecs-vpc.id
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
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
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
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
    tags = {
    Name = "DB-SG-EC2-SITE"
  }
}
#Create a security group
resource "aws_security_group" "open-ingress-by-sg-ingress-site" {
  name        = "OPEN-INGRESS-BY-SG--INGRESS-SITE"
  description = "Allows all connections from selected security group"
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
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
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
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
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
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
  vpc_id      = "${aws_vpc.ecs-vpc.id}"
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
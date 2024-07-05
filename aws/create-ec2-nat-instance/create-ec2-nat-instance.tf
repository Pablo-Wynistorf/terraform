provider "aws" {
  region     = var.var-region
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

variable "var-vpc-id" {
  description = "Enter the name of your vpc"
}

variable "var-instance-ami" {
  description = "Enter the ami of of your nat instance (Must be amazon linux)"
}

variable "var-instance-type" {
  description = "Enter the instance type of your nat instance"
}

variable "var-subnet-id" {
  description = "Enter the subnet id of your nat instance"
}

variable "var-vpc-cidr" {
  description = "Enter the cidr of your vpc"
}


resource "aws_instance" "ec2-nat-instance" {
  ami           = var.var-instance-ami
  instance_type = var.var-instance-type
  subnet_id     = var.var-subnet-id
  vpc_security_group_ids = [aws_security_group.open-ingress-local.id]
  source_dest_check = false
  tags = {
    Name = "NAT-Instance"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo yum install iptables-services -y
  sudo systemctl enable iptables
  sudo systemctl start iptables
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/custom-ip-forwarding.conf
  sudo sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf
  iface=$(netstat -i | grep "BMRU" | awk '{print $1}')
  sudo /sbin/iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE
  sudo /sbin/iptables -F FORWARD
  sudo service iptables save
  EOF
}

output "ec2_instance_id" {
value = "${aws_instance.ec2-nat-instance.id}"
}

resource "aws_security_group" "open-ingress-local" {
  name        = "OPEN-INGRESS-LOCAL"
  description = "All Ports open in vpc cidr"
  vpc_id      = var.var-vpc-id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.var-vpc-cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "OPEN-INGRESS-LOCAL"
  }
}

data "template_file" "render-var-file" {
  template = <<-EOT
var-region            = "${var.var-region}"
var-instance-ami      = "${var.var-instance-ami}"
var-instance-type     = "${var.var-instance-type}"
var-subnet-id         = "${var.var-subnet-id}"
var-vpc-id            = "${var.var-vpc-id}"
var-vpc-cidr          = "${var.var-vpc-cidr}"
  EOT
}

resource "local_file" "create-var-file" {
  content  = data.template_file.render-var-file.rendered
  filename = "terraform.tfvars"
}
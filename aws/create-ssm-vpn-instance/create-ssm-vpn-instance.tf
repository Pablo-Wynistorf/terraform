provider "aws" {
  region = var.region
}

variable "region" {
  description = "In what region do you want the infrastructure?"
  type        = string
}

variable "instance_ami" {
  description = "Enter the AMI of your SSM VPN instance (Must be a Ubuntu)"
  type        = string
}

variable "subnet_id" {
  description = "Enter a subnet ID that has internet access"
  type        = string
}

resource "aws_iam_role" "ssm_vpn_instance_role" {
  name = "ssm-vpn-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = aws_iam_role.ssm_vpn_instance_role.name
  role = aws_iam_role.ssm_vpn_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_role_attachment" {
  role       = aws_iam_role.ssm_vpn_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_instance" "ssm_vpn_instance" {
  ami                    = var.instance_ami
  instance_type          = "t3.nano"
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  tags = {
    Name = "SSM-VPN-INSTANCE"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update
  sudo apt install -y python3 python3-pip
  pip install aws-ssm-tunnel-agent --break-system-packages
  EOF
}

data "template_file" "render_var_file" {
  template = <<-EOT
region            = "${var.region}"
instance_ami      = "${var.instance_ami}"
subnet_id         = "${var.subnet_id}"
  EOT
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected.vpc_id
}

resource "local_file" "create_var_file" {
  content  = data.template_file.render_var_file.rendered
  filename = "terraform.tfvars"
}

output "ssm_vpn_start_command" {
  value = "ssm-tunnel ${aws_instance.ssm_vpn_instance.id} --route ${data.aws_vpc.selected.cidr_block}"
}

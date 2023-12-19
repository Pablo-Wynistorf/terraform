provider "aws" {
  region     = var.var-region
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

variable "var-ami" {
  description = "In what ami do you want for your ec2 instance?"
}

variable "var-instance-type" {
  description = "In what instance type do you want for your ec2 instance?"
}

variable "var-ssh-keyname" {
  description = "In what ssh key do you want to use for your ec2 instance? (Without .pem)"
}

variable "var-private-ip" {
  description = "Set a private ip for your instance"
}

variable "var-subnet-id" {
  description = "Set a subnet id for your instance"
}

variable "var-security_group-id" {
  description = "Set a security group id for your instance"
}

variable "var-volume-size" {
  description = "Set a volume size for your instance (GB)"
}


# Create a new EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = var.var-ami
  instance_type = var.var-instance-type
  key_name      = var.var-ssh-keyname
  private_ip = var.var-private-ip
  subnet_id = var.var-subnet-id
  security_groups = [var.var-security_group-id]


  # Add a root volume
  root_block_device {
    volume_size = var.var-volume-size
    volume_type = "gp2"
  }

}
output "ec2_public_ip" {
value = "${aws_instance.ec2_instance.public_ip}"
}

data "template_file" "render-var-file" {
  template = <<-EOT
var-region            = "${var.var-region}"
var-ami               = "${var.var-ami}"
var-instance-type     = "${var.var-instance-type}"
var-ssh-keyname       = "${var.var-ssh-keyname}"
var-private-ip        = "${var.var-private-ip}"
var-subnet-id         = "${var.var-subnet-id}"
var-security_group-id = "${var.var-security_group-id}"
var-volume-size       = "${var.var-volume-size}"
  EOT
}




resource "local_file" "create-var-file" {
  content  = data.template_file.render-var-file.rendered
  filename = "terraform.tfvars"
}
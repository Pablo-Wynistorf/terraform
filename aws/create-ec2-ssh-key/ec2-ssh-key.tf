provider "aws" {
  region = var.var-region
}
variable "var-region" {
  description = "In what region do you want the infrastructure?"
}


resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "ssh.pem"
}
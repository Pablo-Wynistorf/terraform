# Set the AWS provider
provider "aws" {
  region     = var.var-region
}

variable "var-region" {
  description = "In what region do you want the infrastructure?"
}

# Create a new EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0574da719dca65348"
  instance_type = "t2.large"
  key_name      = "ssh"
  private_ip = "10.1.1.30"
  subnet_id = "subnet-04cd85e056c9c62a5"
  security_groups = ["sg-0d0a98cd48a506b7d"]


  # Add a root volume
  root_block_device {
    volume_size = "10"
    volume_type = "gp2"
  }


user_data = <<EOF
#cloud-config
hostname: nextcloud-server

packages:
  - docker
  - docker-compose
  - net-tools

# Write the Docker Compose file
write_files:
  - path: /nextcloud/docker-compose.yml
    content: |
      version: '2'
      volumes:
        nextcloud:
      services:
        app:
          image: nextcloud
          restart: unless-stopped
          ports:
          - 80:80
          volumes:
          - /nextcloud/data:/var/www/html

runcmd:
  - [sh, -c, "docker-compose -f /nextcloud/docker-compose.yml up -d"]
EOF
}
output "ec2_public_ip" {
value = "${aws_instance.ec2_instance.public_ip}"
}

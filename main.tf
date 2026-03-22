provider "aws" {
  region = "us-east-1" 
}

# Automatically find the latest Amazon Linux 2023 AMI
data "aws_ami" "latest_al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_instance" "jenkins_devops_server" {
  ami           = data.aws_ami.latest_al2023.id
  instance_type = "t3.small"
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # Points to the external shell script
  user_data = file("install_jenkins.sh")

  tags = {
    Name = "Jenkins-Project-Server"
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_project_sg_final"
  description = "Security group for Jenkins DevOps Server"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output the Public IP so you don't have to check the AWS Console
output "jenkins_public_ip" {
  description = "The public IP address of the Jenkins server"
  value       = aws_instance.jenkins_devops_server.public_ip
}

output "jenkins_url" {
  description = "The URL to access the Jenkins UI"
  value       = "http://${aws_instance.jenkins_devops_server.public_ip}:8080"
}
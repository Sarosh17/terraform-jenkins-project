provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "devops_sg" {
  name        = "devops-server-sg"
  description = "Security group for DevOps server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-server-sg"
  }
}

resource "aws_instance" "devops_server" {
  ami                    = "ami-0ddfba243cbee3768"
  instance_type          = "t3.micro"
  key_name               = "devops-key"
  vpc_security_group_ids = [aws_security_group.devops-server-sg.id]

  tags = {
    Name = "Terraform-Jenkins-Server"
  }
}

output "public_ip" {
  value = aws_instance.devops_server.public_ip
}

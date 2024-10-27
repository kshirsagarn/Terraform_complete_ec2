# step-1: Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "--"
  secret_key = "----"
}

# step-2: AWS VPC creation
resource "aws_vpc" "ownvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "ownvpc"
  }
}

# step-3: AWS VPC subnet creation
resource "aws_subnet" "ownsubnet" {
  vpc_id     = aws_vpc.ownvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "own-subnet"
  }
}

# step-4: AWS VPC Internet Gateway (IGW) creation
resource "aws_internet_gateway" "owngw" {
  vpc_id = aws_vpc.ownvpc.id

  tags = {
    Name = "own-igw"
  }
}

# step-5: AWS VPC route table creation
resource "aws_route_table" "my_table" {
  vpc_id = aws_vpc.ownvpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Allows internet access
    gateway_id = aws_internet_gateway.owngw.id
  }

  tags = {
    Name = "own-rt"
  }
}

# step-6: AWS VPC route table association
resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.ownsubnet.id
  route_table_id = aws_route_table.my_table.id
}

# step-7: AWS Security Group Creation
resource "aws_security_group" "mywebsecurity" {
  name        = "my_web_security"
  description = "Allow HTTP and SSH inbound traffic, all outbound"
  vpc_id      = aws_vpc.ownvpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # Allows all outbound traffic
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mywebserver-sg"
  }
}

# step-08: AWS Instance Creation
resource "aws_instance" "webserver" {
  ami                         = "ami-06b21ccaeff8cd686"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.ownsubnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mywebsecurity.id]
  key_name                    = "key"

  user_data = <<-EOF
  #!/bin/bash
  sudo yum install httpd -y
  sudo systemctl start httpd
  sudo systemctl enable httpd
  EOF

  tags = {
    Name = "tf-1"
  }
}

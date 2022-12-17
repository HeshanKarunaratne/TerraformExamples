provider "aws" {
  region = "us-east-1"
}

//ec2-instance
resource "aws_instance" "ec2-instance" {
  ami           = "ami-085925f297f89fce1"
  instance_type = "t2.micro"
  tags = {
    "Name" = "my-server"
  }
}

output "public_ip" {
  value = aws_instance.ec2-instance.public_ip
}

//vpc
resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "production"
  }
}

//subnet
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    "Name" = "prod-subnet"
  }
}

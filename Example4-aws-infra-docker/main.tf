# Steps
# 1 Create custom VPC
# 2 Create custom Subnet
# 3 Create Route Table & Internet Gateway
# 4 Create Security Group (Firewall)
# 5 Deploy nginx Docker container
# 6 Provision EC2 Instance

# Define which provider to be used - Terraform supports AWS
provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}
variable "private_key_location" {}

# Step 1
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    # variable interpolation inside String
    Name = "${var.env_prefix}-vpc",
  }
}

# Step 2
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

# Step 3a1 - Generate a Route table for the VPC
# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name = "${var.env_prefix}-route-table"
#   }
# }

# Step 3a2 - For the Route Table need a Internet Gateway inside the VPC
# Step 3b1 - Using the default route table
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-internet-gateway"
  }
}

# Step 3a3 To create the Subnet Association between Route table to Subnet
# resource "aws_route_table_association" "myapp-route-table-association-subnet" {
#   subnet_id = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }

# Step 3b2 - Using the default Route table rather than creating a new route table
resource "aws_default_route_table" "myapp-default-route-table" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-main-route-table"
  }
}

# Step 4a - Creating New Security Group 
# resource "aws_security_group" "myapp-security-group" {
#   name = "myapp-security-group"
#   vpc_id = aws_vpc.myapp-vpc.id

#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "ssh"
#     # my ip address - only allows to this ip
#     cidr_blocks = [var.my_ip]
#   }

#   ingress {
#     from_port = 8080
#     to_port = 8080
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     prefix_list_ids = []
#   }
#   tags = {
#     Name = "${var.env_prefix}-security-group"
#   }
# }

# Step 4b - Using default Security Group 
resource "aws_default_security_group" "default-security-group" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "ssh"
    # my ip address - only allows to this ip
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-default-security-group"
  }
}

# Step 5a - Dynamically populate AMI id 
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64_gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Step 5b - Output AMI values 
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

# Using id_rsa.pub key to authenticate 
resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}

# Step 5c - Create AWS EC2 Instance - AMI
resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  # To put the EC2 instance in our own VPC, own subnet, own availability zone rather than using default values
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-security-group.id]
  availability_zone      = var.avail_zone

  # Access from browser and for ssh
  associate_public_ip_address = true

  # Create a .pem file so that the EC2 instance can access through ssh
  key_name = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "${var.env_prefix}-server"
  }

  # Step a1 -  startup scripts - only executed once - can use provisioners as well
  # user_data = <<EOF
  #               #!/bin/bash
  #               sudo yum update -y && sudo yum install -y docker
  #               sudo systemctl start docker
  #               sudo usermod -aG docker ec2-user
  #               docker run -p 8080:80 nginx
  #             EOF

  connection {
    type        = "ssh"
    host        = self.pulic_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source      = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }

  # Step a2 - Using provisioners
  provisioner "remote-exec" {
    script = file("entry-script-on-ec2.sh")
  }
}





/*

Route table - Need to handle internet coming in and out of Internet Gateway
NACL - Subnet level - Open by default
Security Group - Server level - Close by default

///////////////////////////////////////////////////////////////////////////////////////////////////////
# terraform plan : Gives you the desired state 
# terraform apply --auto-approve : Apply the changes to terraform without confirming
# terraform state show aws_vpc.myapp-vpc : Show all the values of the AWS VPC "myapp-vpc"
///////////////////////////////////////////////////////////////////////////////////////////////////////



# data - Filter from created resource
data "aws_vpc" "existing_vpc" {
  default = true
}

# output - Gives an output of requested params
output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id 
}

# terraform init : Initialize terraform
# terraform apply : Apply the changes to terraform 
# terraform destroy -target {resource_type}.{resource_name} : Destroy specific resources by resource name
# terraform state list : List resources in the state
# terraform apply -var-file terraform-dev.tfvars : If have multiple environments need to pass the file when applying

*/

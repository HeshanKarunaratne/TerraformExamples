# Define which provider to be used - Terraform supports AWS
provider "aws" {
  # Configuration options
  profile = "default"
  region = "us-east-1"

  # Do not hardcode credentials
  # access_key = "ASIAZCEMJ4NEZTZBVIWJ"
  # secret_key = "P+UOtOKaej+xBw8sVgpCuCeZu8E7w9eVw+Cuhmos"
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}

# resource - Create a VPC resource called "development-vpc"
resource "aws_vpc" "development-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "development",
    vpc_env = "dev"
  }
}

# prompt : 1st way of passing a variable 
# terraform apply -var "subnet_cidr_block=10.0.10.0/24" : 2nd way of passing a variable
variable "subnet_cidr_block" { 
  description = "subnet cidr block"
  default = "10.0.10.0/24" 
  type = string
}

variable "cidr_blocks" {
  description = "cidr block values"
  type = list(object({
    cidr_block = string
    name = string
  }))
}

# resource - Create a Subnet resource called "dev-subnet-1" inside "development-vpc" using its id
resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.cidr_blocks[1].cidr_block
  availability_zone = "us-east-1a"
  tags = {
    Name = var.cidr_blocks[1].name
  }
}

# data - Filter from created resource
data "aws_vpc" "existing_vpc" {
  default = true
}

# custom environmental variables : export TF_VAR_avail_zone
# variable "avail_zone" {
# }

variable "subnet_cidr_block_dev2" {
  description = "subnet cidr block for dev 2"
  type = list(string)
}

# resource - Create a New Subnet "dev-subnet-2" from earlier filtered data
resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block = var.subnet_cidr_block_dev2[1]
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet-2-default"
  }
}

# output - Gives an output of requested params
output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id 
}

output "dev-subnet-id" {
  value = aws_subnet.dev-subnet-1.id
}
////////////////////////////////////////////////////////////
# terraform init : Initialize terraform
# terraform apply : Apply the changes to terraform 
# terraform destroy -target {resource_type}.{resource_name} : Destroy specific resources by resource name
# terraform plan : Gives you the desired state 
# terraform apply -auto-approve : Apply the changes to terraform without confirming
# terraform state list : List resources in the state
# terraform apply -var-file terraform-dev.tfvars : If have multiple environments need to pass the file when applying

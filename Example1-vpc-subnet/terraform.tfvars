subnet_cidr_block = "10.0.20.0/24"
vpc_cidr_block = "10.0.0.0/16"
subnet_cidr_block_dev2 = ["10.0.20.0/24","10.0.0.0/16"]

cidr_blocks = [
    {cidr_block = "10.0.20.0/24" , name = "dev-vpc"},
    {cidr_block = "10.0.30.0/16" , name = "dev-subnet"}
]
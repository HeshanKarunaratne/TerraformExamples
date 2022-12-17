resource "aws_default_security_group" "default-security-group" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "ssh"
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

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.image_name]
    //values = ["amzn2-ami-hvm-*-x86_64_gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  # subnet_id                   = aws_subnet.myapp-subnet-1.id
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_default_security_group.default-security-group.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "${var.env_prefix}-server"
  }

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

  provisioner "remote-exec" {
    script = file("entry-script-on-ec2.sh")
  }
}

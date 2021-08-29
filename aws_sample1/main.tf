#Variable declaration
variable aws_region {}
variable aws_avail_zone {}
variable aws_access_key {}
variable aws_secret_key {}
variable env_prefix {}
variable instance_type {}
variable my_ip {}
variable subnet_cidr_block {}
variable vpc_cidr_block {
    description = "cidr blocks and name tags for vpc and subnets"
    type        = string
}

#Providers
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region     = var.aws_region
}

#All resources and data blocks in ordering which considering dependency
#Dependent resources are defined in the file before those that depend on them
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name= "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id            = aws_vpc.myapp-vpc.id
    cidr_block        = var.subnet_cidr_block
    availability_zone = var.aws_avail_zone

    tags = {
        Name= "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw"{
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        Name = "${var.env_prefix}-igw"
    }
} 

resource "aws_default_route_table" "main-rtb"{
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}

resource "aws_default_security_group" "default-sg"{
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
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
        Name = "${var.env_prefix}-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}



resource "aws_instance" "myapp-server" {
    ami                         = data.aws_ami.latest-amazon-linux-image.id
    instance_type               = var.instance_type
    subnet_id                   = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
    availability_zone           = var.aws_avail_zone
    associate_public_ip_address = true
    key_name                    = "aashu-key-pair"

    user_data = <<EOF
                   #!/bin/bash
                   sudo yum update -y && sudo yum install -y docker
                   sudo systemctl start docker
                   sudo usermod -aG docker ec2-user
                   docker run -p 8080:80 nginx
                EOF

    tags = {
        Name = "${var.env_prefix}-server"
    }
}                   

#All output blocks in alphabetical order 
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image
}

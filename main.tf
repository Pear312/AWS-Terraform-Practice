provider "aws" {
  region = "us-east-1"
}


// VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "NextWork VPC"
  }
}


// Public Subnet 
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "NextWork Public Subnet"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "NextWork IG"
  }
}


// Route Table
resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "NextWork Public Route Table"
  }
}

resource "aws_route_table_association" "subnet_assoc" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod_route_table.id
}


// Security Group
resource "aws_security_group" "nextwork_sg" {
  name        = "NextWork Security Group"
  description = "A Security Group for the NextWork VPC."
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "NextWork Security Group"
  }
}

// Private security group
resource "aws_security_group" "nextwork_sg_private" {
  name        = "NextWork Private Security Group"
  description = "A Security Group for the NextWork Private subnet."
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "SSH from public security group"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.nextwork_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "NextWork Private Security Group"
  }
}


// Network ACL
resource "aws_network_acl" "acl" {
  vpc_id = aws_vpc.prod_vpc.id
  subnet_ids = [aws_subnet.subnet_1.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "NextWork ACL"
  }
}


// Private Subnet
resource "aws_subnet" "Private_subnet" {
  vpc_id     = aws_vpc.prod_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "NextWork Private Subnet"
  }
}

// Route table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "NextWork Private Route Table"
  }
}

resource "aws_route_table_association" "private_subnet_assoc" {
  subnet_id      = aws_subnet.Private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

// Private subnet ACL
resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.prod_vpc.id
  subnet_ids = [aws_subnet.Private_subnet.id]

  tags = {
    Name = "NextWork Private NACL"
  }
}


#
# Launch EC2 into both private and public subnets
#

// Public EC2
resource "aws_instance" "public_server" {
  ami = "ami-0bdc7d025135d7b49"
  instance_type = "t2.micro"
  key_name = "devKey"

  subnet_id = aws_subnet.subnet_1.id

  vpc_security_group_ids = [aws_security_group.nextwork_sg.id]

  tags = {
    Name = "NextWork public instance"
  }
}

// Private EC2
resource "aws_instance" "private_server" {
  ami = "ami-0bdc7d025135d7b49"
  instance_type = "t2.micro"
  key_name = "devKey"

  subnet_id = aws_subnet.Private_subnet.id

  vpc_security_group_ids = [aws_security_group.nextwork_sg_private.id]

  tags = {
    Name = "NextWork private instance"
  }
}


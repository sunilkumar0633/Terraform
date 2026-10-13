terraform {
  required_version = "~>1.16.0"
  required_providers {
    aws = {
      version = "6.67.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Step-1 Create VPC

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "myvpc"
    env  = "test"
  }
}

# Step-2 Create Public subnet

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/18"
  tags = {
    name = "pub_subnet"
    env  = "test"
  }
}

# Step-3 Create Private subnet - 1

resource "aws_subnet" "private_subnet-1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.64.0/18"
  tags = {
    name = "private_subnet-1"
    env  = "test"
  }
}

# Step-4 Create Private subnet - 2
resource "aws_subnet" "private_subnet-2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.128.0/18"
  tags = {
    name = "private_subnet-2"
    env  = "test"
  }
}

# Step-5 Create IGW

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    name = "my_igw"
    env  = "test"
  }
}


# Step - 6 Create elastic IP for Natgateway
resource "aws_eip" "nat_ip" {
  domain = "vpc"
  tags = {
    name = "nat_ip"
    env  = "test"
  }
}

# Step - 7 Create NAT Gateway
resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    name = "my_nat"
    env  = "test"
  }
}


# Step - 8 Create route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    name = "public_rt"
    env  = "test"
  }
}

# Step - 9 Create route table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat.id
  }
  tags = {
    name = "private_rt"
    env  = "test"
  }
}

#step - 10 Private subnet association 

resource "aws_route_table_association" "private_rt_association" {
  count = 2
  subnet_id = element([
    aws_subnet.private_subnet-1.id,
    aws_subnet.private_subnet-2.id
  ], count.index)
  route_table_id = aws_route_table.private_route_table.id
}


#step - 12  Public subnet association 
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id

}

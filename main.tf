resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}



# Public Subnet in Default VPC
resource "aws_subnet" "public" {
   vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.31.100.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.31.101.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}
# Private Subnet in Default VPC
resource "aws_subnet" "private" {
 vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.31.102.0/24"

  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private1" {
 vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.31.103.0/24"

  availability_zone = "us-east-1b"
}


# Security Groups
resource "aws_security_group" "allow_internal" {
  name = "allow_internal"
  description = "Allow internal traffic"
  vpc_id = aws_default_vpc.default.id
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH from jump server"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    #security_group_names = [aws_security_group.allow_internal.name]
  #  cidr_blocks = "0.0.0.0/0"
  }

  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
}

# EC2 Instance (Jump Server) in Public Subnet
resource "aws_instance" "jump_server" {
  ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  #subnet_id = "{aws_subnet.public.id}"
   vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}

# RDS Instance in Private Subnet
resource "aws_db_instance" "rds" {
  identifier = "myrds"
  engine = "mysql" # or your preferred RDS engine
  instance_class = "db.t2.micro" # or your preferred instance type
  allocated_storage = 20
  storage_type = "gp3"
  username = "admin"
  password = "admin1234"
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.allow_internal.id]
  skip_final_snapshot = "true"
  copy_tags_to_snapshot = "false"

}
  resource "aws_db_subnet_group" "default" {
  name       = "main"
  #subnet_ids = ["${module.vpc.private_subnets[0]}", "${module.vpc.private_subnets[1]}"]
  subnet_ids = [aws_subnet.private.id, aws_subnet.private1.id]
  tags = {
    Name = "My DB subnet group"
  }
  }


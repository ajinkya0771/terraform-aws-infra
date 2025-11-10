locals {
  name = var.project_name
}

# ✅ Fetch available AZs
data "aws_availability_zones" "available" {}

# ✅ Fetch Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# ✅ Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${local.name}-vpc"
  }
}

# ✅ Create Subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "${local.name}-public-subnet" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "${local.name}-private-subnet" }
}

# ✅ Additional Private Subnet for RDS (in another AZ)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${local.name}-private-subnet-2"
  }
}

# ✅ Internet Gateway for Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${local.name}-igw" }
}

# ✅ Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${local.name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ✅ Security Groups
resource "aws_security_group" "web_sg" {
  name        = "${local.name}-web-sg"
  description = "Allow SSH & HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "SSH Access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP Access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-web-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "${local.name}-db-sg"
  description = "Allow MySQL traffic from Web SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-db-sg" }
}

# ✅ Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${local.name}-key"
  public_key = file(var.public_key_path)
}

# ✅ EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              echo "<h1>Terraform EC2 Web Server</h1>" > /var/www/html/index.html
              systemctl start nginx
              EOF

  tags = { Name = "${local.name}-ec2" }
}

# ✅ DB Subnet Group & RDS
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${local.name}-db-subnets"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]
  tags       = { Name = "${local.name}-db-subnet-group" }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "mysql" {
  identifier              = "${local.name}-mysql"
  allocated_storage       = var.db_allocated_storage
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  tags = { Name = "${local.name}-mysql" }
}

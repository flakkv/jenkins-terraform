provider "aws" {
  region = "eu-central-1"
}

provider "random" {}

# EC2 for Ghost
resource "aws_instance" "ghost_server" {
  ami           = "ami-0xxxxxx"  # Replace with the appropriate Ubuntu 22 AMI ID for eu-central-1 when it's available.
  instance_type = "t2.micro"
  key_name      = "your_existing_key_name"  # Replace with the name of your existing key.
  vpc_security_group_ids = [aws_security_group.ghost_sg.id]

  tags = {
    Name = "GhostServer"
  }
}

resource "aws_security_group" "ghost_sg" {
  name        = "ghost_sg"
  description = "Security Group for Ghost CMS server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2368
    to_port     = 2368
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS for MySQL
resource "aws_db_instance" "ghost_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = "ghost_db"
  username             = "ghostadmin"
  password             = random_password.db_password.result
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}

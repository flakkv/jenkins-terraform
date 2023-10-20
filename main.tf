provider "aws" {
  region = "eu-central-1"
}

provider "random" {}

resource "aws_instance" "ghost_server" {
  ami           = "ami-06dd92ecc74fdfb36"  # Replace with the appropriate Ubuntu 22 AMI ID for eu-central-1 when it's available.
  instance_type = "t2.micro"
  key_name      = "e570"  # Replace with the name of your existing key.
  vpc_security_group_ids = [aws_security_group.ghost_sg.id]

  user_data = <<-EOT
              #!/bin/bash
              apt-get update
              apt-get install -y nginx mysql-client
              curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash
              apt-get install -y nodejs
              node -v && npm -v
              npm install ghost-cli@latest -g
              PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
              ghost install --db=mysql --dbhost=${aws_db_instance.ghost_db.address} --dbuser=ghostadmin --dbpass=${random_password.db_password.result} --dbname=ghost_db --url=http://temporary-url-placeholder --no-prompt --no-stack
              EOT

  tags = {
    Name = "GhostServer"
  }
}

resource "aws_security_group" "ghost_sg" {
  name        = "GhostSecurityGroup"
  description = "Security group for Ghost Server"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "ghost_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = "ghostdb"
  username             = "ghostadmin"
  password             = random_password.db_password.result
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

output "db_password" {
  value = random_password.db_password.result
}

output "ghost_server_ip" {
  value = aws_instance.ghost_server.public_ip
}

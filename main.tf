provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "ghost_server" {
  ami           = "ami-06dd92ecc74fdfb36"  # Remember to replace this with the appropriate AMI for your region.
  instance_type = "t2.micro"
  key_name      = "e570"  # Replace with the name of your existing key.
  vpc_security_group_ids = [aws_security_group.ghost_sg.id]

  user_data = <<-EOT
              #!/bin/bash
              adduser ghostuser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
              echo "ghostuser:ghost_password" | chpasswd
              usermod -aG sudo ghostuser

              apt-get update
              apt-get upgrade -y
              apt-get install -y nginx mysql-server ca-certificates curl gnupg ufw

              ufw allow 'Nginx Full'

              mkdir -p /etc/apt/keyrings
              curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
              echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x $(lsb_release -cs) main" > /etc/apt/sources.list.d/nodesource.list

              apt-get update
              apt-get install -y nodejs
              npm install ghost-cli@latest -g

              su - ghostuser -c 'mkdir -p /var/www/ghost && cd /var/www/ghost && ghost install --db=mysql --dbhost=localhost --dbuser=root --dbname=ghost_db --url=http://temporary-url-placeholder --no-prompt --no-stack'
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

output "ghost_server_ip" {
  value = aws_instance.ghost_server.public_ip
}

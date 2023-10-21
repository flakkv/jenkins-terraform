provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "ghost_server" {
  ami           = "ami-06dd92ecc74fdfb36"  # Replace this with the appropriate AMI for your region.
  instance_type = "t2.micro"
  key_name      = "e570"  # Replace with the name of your existing key.
  vpc_security_group_ids = [aws_security_group.ghost_sg.id]

  user_data = <<-EOT
              #!/bin/bash
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Create Docker Compose file
              cat > /root/docker-compose.yml <<EOF
version: '3.1'
services:
  ghost:
    image: ghost:4-alpine
    restart: always
    ports:
      - 8080:2368
    environment:
      database__client: mysql
      database__connection__host: db
      database__connection__user: root
      database__connection__password: example
      database__connection__database: ghost
      url: http://localhost:8080
  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
EOF
              
              # Start Docker Compose
              docker-compose -f /root/docker-compose.yml up -d
  EOT

  tags = {
    Name = "GhostServer"
  }
}

resource "aws_security_group" "ghost_sg" {
  name        = "GhostSecurityGroup"
  description = "Security group for Ghost Server"

  ingress {
    from_port   = 8080
    to_port     = 8080
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

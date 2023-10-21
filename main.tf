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
              # Add Docker's official GPG key:
              apt-get update
              apt-get install -y ca-certificates curl gnupg
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg

              # Add the repository to Apt sources:
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update

              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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

              # Start services with Docker Compose
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

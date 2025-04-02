terraform {
    required_providers {
    aws = {
        source  = "hashicorp/aws"
    }
    }
    required_version = ">= 1.2.0"
}

provider "aws" {
    shared_config_files      = ["/Users/Usuario/.aws/config"]
    shared_credentials_files = ["/Users/Usuario/.aws/credentials"]
}

resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = var.instancia
  subnet_id                   = aws_subnet.subnetPublica.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.grupo_seguridad.id]
  key_name                    = "clave"
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip python3-dev git
              
              # Clonar el repositorio
              cd /home/ubuntu
              git clone https://github.com/DanielJimenez357/despliegue_django django_app
              
              cd django_app/tarea_2_periodo_recuperacion
              pip3 install django
              
              python3 manage.py migrate
              
              cat > /etc/systemd/system/django.service <<EOL
              [Unit]
              Description=Django Application Service
              After=network.target
              [Service]
              User=ubuntu
              Group=ubuntu
              WorkingDirectory=/home/ubuntu/django_app/tarea_2_periodo_recuperacion
              ExecStart=/usr/bin/python3 manage.py runserver 0.0.0.0:80
              Restart=always
              [Install]
              WantedBy=multi-user.target
              EOL
              chown -R ubuntu:ubuntu /home/ubuntu/django_app
              systemctl daemon-reload
              systemctl enable django
              systemctl start django
              EOF

  tags = {
    Name = "django-server"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

resource "aws_security_group" "grupo_seguridad" {
  name        = "grupo_seguridad"
  description = "grupo_seguridad"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = {
    Name = "grupo_seguridad"
  }
}



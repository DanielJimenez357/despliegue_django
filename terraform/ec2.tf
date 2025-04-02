terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
          
          mkdir -p ~/django_app
          cd ~/django_app
          git clone https://github.com/DanielJimenez357/despliegue_django .
          pip3 install django
          
          DJANGO_DIR=$(find ~/django_app -name manage.py -exec dirname {} \;)
          
          cat > /etc/systemd/system/django.service <<EOL
          [Unit]
          Description=Django Application Service
          After=network.target
          [Service]
          User=$(whoami)
          Group=$(whoami)
          WorkingDirectory=$DJANGO_DIR
          Environment=PATH=$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          ExecStart=$HOME/.local/bin/python3 manage.py runserver 0.0.0.0:80
          Restart=always
          [Install]
          WantedBy=multi-user.target
          EOL
          
          chmod 644 /etc/systemd/system/django.service
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



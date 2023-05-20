provider "aws" {
  access_key = "<key_AWS>"
  secret_access_key = "<secret_key_AWS>"
  region = "us-west-2"
}


resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16" 
  tags = {
    Name = "Vpc"
  }
}


resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a" 
  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b" 
  tags = {
    Name = "Subnet2"
  }
}

resource "aws_security_group" "my_s_gr" {
  name        = "MY sgroup"
  description = "MySecurityGroup"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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


resource "aws_instance" "instance1" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  subnet_id  = aws_subnet.sub1.id
  key_name  = "example_key_pair"  
  vpc_security_group_ids = [aws_security_group.my_s_gr.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y prometheus

              cat <<EOT > /etc/prometheus/prometheus.yml
              global:
                scrape_interval: 15s
                evaluation_interval: 15s

              scrape_configs:
                - job_name: 'node-exporter'
                  static_configs:
                    - targets: ['localhost:9100']

                - job_name: 'cadvisor-exporter'
                  static_configs:
                    - targets: ['localhost:8080']
              EOT

              systemctl enable prometheus
              systemctl start prometheus

              apt-get install -y node-exporter
              systemctl enable node-exporter
              systemctl start node-exporter

              sudo apt-get install -y cadvisor
              systemctl enable cadvisor
              systemctl start cadvisor
              EOF

  tags = {
    Name = "Instance1"
  }
}


resource "aws_instance" "instance2" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  subnet_id  = aws_subnet.sub2.id
  key_name  = "example_key_pair"  
  vpc_security_group_ids = [aws_security_group.my_s_gr.id]
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y node-exporter cadvisor

              systemctl enable node-exporter
              systemctl start node-exporter

              systemctl enable cadvisor
              systemctl start cadvisor
              EOF

  tags = {
    Name = "Instance2"
  }
}
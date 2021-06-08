provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.10.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags {
    Name     = "vpc"
    Location = "Saint Petersburg"
  }
}

resource "aws_internet_gateway" "int-gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "int-gateway"
  }
}

resource "aws_subnet" "pub-subnet-1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags {
    Name = "pub-subnet-1"
  }
}

resource "aws_subnet" "pub-subnet-2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags {
    Name = "pub-subnet-2"
  }
}

resource "aws_route_table" "pub-route-table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.int-gateway.id}"
  }

  tags {
    Name = "pub-route-table"
  }
}

resource "aws_route_table_association" "pub-route-table-1" {
  subnet_id      = "${aws_subnet.pub-subnet-1.id}"
  route_table_id = "${aws_route_table.pub-route-table.id}"
}

resource "aws_route_table_association" "pub-route-table-2" {
  subnet_id      = "${aws_subnet.pub-subnet-2.id}"
  route_table_id = "${aws_route_table.pub-route-table.id}"
}

resource "aws_security_group" "sec-group" {
  name        = "sec-group"
  description = "HTTP SSH ICMP"
  vpc_id      = "${aws_vpc.vpc.id}"

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
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sec-group"
  }
}

resource "aws_instance" "web-srv-1" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  key_name      = "epamssh"

  subnet_id = "${aws_subnet.pub-subnet-1.id}"

  vpc_security_group_ids = ["${aws_security_group.sec-group.id}"]

  user_data = <<-EOF
              #!/bin/bash
              su
              apt -y update
              apt -y install apache2
              echo "Hi It's my Site 1" > index.html
              cp index.html /var/www/html/index.html
              service apache2 start
              chkconfig apache2 on
              EOF

  tags = {
    Name  = "Web Server 1"
    Owner = "Ilya Polishchuk"
  }
}

resource "aws_instance" "web-srv-2" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  key_name      = "epamssh"

  subnet_id = "${aws_subnet.pub-subnet-2.id}"

  vpc_security_group_ids = ["${aws_security_group.sec-group.id}"]

  user_data = <<-EOF
              #!/bin/bash
              su
              apt -y update
              apt -y install apache2
              echo "Hi It's my Site 2" > index.html
              cp index.html /var/www/html/index.html
              service apache2 start
              chkconfig apache2 on
              EOF

  tags = {
    Name  = "Web Server 2"
    Owner = "Ilya Polishchuk"
  }
}

resource "aws_lb_target_group" "alb-tg" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  name        = "alb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${aws_vpc.vpc.id}"
}

resource "aws_lb_target_group_attachment" "alb-tg-1" {
  target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
  target_id        = "${aws_instance.web-srv-1.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "alb-tg-2" {
  target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
  target_id        = "${aws_instance.web-srv-2.id}"
  port             = 80
}

resource "aws_lb" "app-lb" {
  name                       = "app-lb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = ["${aws_subnet.pub-subnet-1.id}", "${aws_subnet.pub-subnet-2.id}"]
  security_groups            = ["${aws_security_group.sec-group.id}"]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "list-alb" {
  load_balancer_arn = "${aws_lb.app-lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
  }
}

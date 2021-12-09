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

resource "aws_security_group" "sec-ec2" {
  name        = "sec-ec2"
  description = "Allow SSH & HTTP"
  vpc_id      = "${aws_vpc.vpc.id}"

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

  tags {
    Name = "sec-ec2"
  }
}

resource "aws_security_group" "sec-sql" {
  name        = "sec-sql"
  description = "Allow SQL"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "sec-sql"
  }
}

resource "aws_security_group_rule" "sec-sql-in" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.sec-ec2.id}"
  security_group_id        = "${aws_security_group.sec-sql.id}"
}

resource "aws_security_group_rule" "sec-sql-out" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sec-sql.id}"
}

resource "aws_security_group" "sec-nfs" {
  name        = "sec-nfs"
  description = "Allow EFS"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "sec-nfs"
  }
}

resource "aws_security_group_rule" "sec-nfs-in" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.sec-ec2.id}"
  security_group_id        = "${aws_security_group.sec-nfs.id}"
}

resource "aws_security_group_rule" "sec-nfs-out" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sec-nfs.id}"
}

resource "aws_instance" "web-srv-1" {
  ami           = "${var.debian_ami_id}"
  instance_type = "t2.micro"
  key_name      = "${var.ssh_key_id}"

  subnet_id = "${aws_subnet.pub-subnet-1.id}"

  vpc_security_group_ids = ["${aws_security_group.sec-ec2.id}"]

  user_data = "${file("install_web.sh")}"

  tags = {
    Name  = "Web Server 1"
    Owner = "Ilya Polishchuk"
  }
}

resource "aws_instance" "web-srv-2" {
  ami           = "${var.debian_ami_id}"
  instance_type = "t2.micro"
  key_name      = "${var.ssh_key_id}"

  subnet_id = "${aws_subnet.pub-subnet-2.id}"

  vpc_security_group_ids = ["${aws_security_group.sec-ec2.id}"]

  user_data = "${file("install_web.sh")}"

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
  security_groups            = ["${aws_security_group.sec-ec2.id}"]
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

module "rds" {
  source                              = "terraform-aws-modules/rds/aws"
  identifier                          = "wordpress"
  engine                              = "mysql"
  engine_version                      = "5.7.26"
  instance_class                      = "db.t2.micro"
  allocated_storage                   = 5
  name                                = "wordpress"
  username                            = "dbadmin"
  password                            = "AdminPass"
  port                                = "3306"
  iam_database_authentication_enabled = true
  vpc_security_group_ids              = ["${aws_security_group.sec-sql.id}"]
  subnet_ids                          = ["${aws_subnet.pub-subnet-1.id}", "${aws_subnet.pub-subnet-2.id}"]
  family                              = "mysql5.7"
  major_engine_version                = "5.7"
  version                             = "~> 1.37"
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  backup_window                       = "03:00-06:00"
}

resource "aws_efs_file_system" "nfs" {
  creation_token = "nfs-ec2"
  encrypted      = "false"
}

resource "aws_efs_mount_target" "nfs-mt-1" {
  file_system_id  = "${aws_efs_file_system.nfs.id}"
  subnet_id       = "${aws_subnet.pub-subnet-1.id}"
  security_groups = ["${aws_security_group.sec-nfs.id}"]
}

resource "aws_efs_mount_target" "nfs-mt-2" {
  file_system_id  = "${aws_efs_file_system.nfs.id}"
  subnet_id       = "${aws_subnet.pub-subnet-2.id}"
  security_groups = ["${aws_security_group.sec-nfs.id}"]
}

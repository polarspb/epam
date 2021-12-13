# ----- Terraform ------

provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "latest-amazon2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ----- Network -----

resource "aws_vpc" "epam-vpc" {
  cidr_block           = "10.10.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = { Name = "epam-vpc" }
}

resource "aws_internet_gateway" "epam-igw" {
  vpc_id = aws_vpc.epam-vpc.id

  tags = { Name = "epam-gateway" }
}

resource "aws_subnet" "epam-pub-net-1" {
  vpc_id                  = aws_vpc.epam-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "epam-public-subnet-1" }
}

resource "aws_subnet" "epam-pub-net-2" {
  vpc_id                  = aws_vpc.epam-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = { Name = "epam-public-subnet-2" }
}

resource "aws_route_table" "epam-pub-rt" {
  vpc_id = aws_vpc.epam-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.epam-igw.id
  }

  tags = { Name = "epam-public-route-table" }
}

resource "aws_route_table_association" "epam-pub-rt-1" {
  subnet_id      = aws_subnet.epam-pub-net-1.id
  route_table_id = aws_route_table.epam-pub-rt.id
}

resource "aws_route_table_association" "epam-pub-rt-2" {
  subnet_id      = aws_subnet.epam-pub-net-2.id
  route_table_id = aws_route_table.epam-pub-rt.id
}

# ----- Security -----

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

  provisioner "local-exec" { # Key *.pem will be create in current directory
    command = "echo '${tls_private_key.dev_key.private_key_pem}' > ./'${var.generated_key_name}'.pem"
  }

  provisioner "local-exec" {
    command = "chmod 400 ./'${var.generated_key_name}'.pem"
  }
}

# ----- Web security -----
resource "aws_security_group" "epam-sg-web" {
  name        = "epam-sg-web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.epam-vpc.id

  dynamic "ingress" {
    for_each = ["22", "80", "443", "8080", "9000"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "epam-sg-web" }
}

# resource "aws_security_group" "epam-sg-eks" {
#   name        = "epam-sg-eks"
#   description = "Allow EKS traffic"
#   vpc_id      = aws_vpc.epam-vpc.id

#   dynamic "ingress" {
#     for_each = ["22", "80", "443", "8080"]
#     content {
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = { Name = "epam-sg-eks" }
#   #tags = merge(var.common-tags, { Name = "${var.common-tags["Environment"]} Dynamic Security Group" })
# }

# # ----- DB security -----
resource "aws_security_group" "epam-sg-db" {
  name        = "epam-sg-db"
  description = "Allow SQL traffic"
  vpc_id      = aws_vpc.epam-vpc.id

  tags = { Name = "epam-sg-db" }
}

resource "aws_security_group_rule" "epam-sg-db-in" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.epam-sg-web.id
  security_group_id        = aws_security_group.epam-sg-db.id
}

# resource "aws_security_group_rule" "epam-sg-db-in-eks" {
#   type                     = "ingress"
#   from_port                = 3306
#   to_port                  = 3306
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.epam-sg-eks.id
#   security_group_id        = aws_security_group.epam-sg-db.id
# }

resource "aws_security_group_rule" "epam-sg-db-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.epam-sg-db.id
}

# ----- EC2 Instances -----

# resource "aws_instance" "epam-control" {
#   ami                    = data.aws_ami.latest-amazon2.id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.epam-pub-net-1.id
#   vpc_security_group_ids = [aws_security_group.epam-sg-web.id]
#   # key_name               = aws_key_pair.generated_key.key_name
#   tags = { Name = "epam-control" }
#   # tags = merge(var.common-tags, { Name = "${var.common-tags["Environment"]} Control Server" })
# }

resource "aws_instance" "epam-jenkins" {
  ami                    = data.aws_ami.latest-amazon2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.epam-pub-net-1.id
  vpc_security_group_ids = [aws_security_group.epam-sg-web.id] 
  key_name               = aws_key_pair.generated_key.key_name
  user_data              = <<EOF
#!/bin/bash
sudo amazon-linux-extras install epel -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum -y install epel-release # repository that provides 'daemonize'
sudo amazon-linux-extras install java-openjdk11 -y
sudo yum install java-11-openjdk-devel -y
sudo yum -y install jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins
EOF
  tags = { Name = "epam-jenkins" }
}

# ----- Create DB instance -----

resource "aws_db_instance" "epam-rds" {
  identifier             = "epam-db"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "5.7.34"
  instance_class         = "db.t2.micro"
  name                   = "epamdb"
  username               = "epam"
  password               = "epampass"
  port                   = "3306"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  apply_immediately      = true
}

# module "rds" {
#   source                              = "terraform-aws-modules/rds/aws"
#   identifier                          = "wordpress"
#   engine                              = "mysql"
#   engine_version                      = "5.7.26"
#   instance_class                      = "db.t2.micro"
#   allocated_storage                   = 5
#   name                                = "wordpress"
#   username                            = "dbadmin"
#   password                            = "AdminPass"
#   port                                = "3306"
#   iam_database_authentication_enabled = true
#   vpc_security_group_ids              = ["${aws_security_group.sec-sql.id}"]
#   subnet_ids                          = ["${aws_subnet.pub-subnet-1.id}", "${aws_subnet.pub-subnet-2.id}"]
#   family                              = "mysql5.7"
#   major_engine_version                = "5.7"
#   version                             = "~> 1.37"
#   maintenance_window                  = "Mon:00:00-Mon:03:00"
#   backup_window                       = "03:00-06:00"
# }

# ----- Kubernates cluster -----

resource "aws_iam_role" "epam-eks-cluster" {
  name = "epam-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.epam-eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.epam-eks-cluster.name
}

resource "aws_eks_cluster" "epam-eks-cluster" {
  name     = "epam-eks-cluster"
  role_arn = aws_iam_role.epam-eks-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.epam-sg-web.id]
    subnet_ids         = [aws_subnet.epam-pub-net-1.id, aws_subnet.epam-pub-net-2.id]
  }

  tags = {
    Name = "epam-eks-cluster"
  }
}

resource "aws_iam_role" "epam-eks-nodes" {
  name = "epam-eks-nodes"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.epam-eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.epam-eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.epam-eks-nodes.name
}

resource "aws_eks_node_group" "epm-eks-nodes" {
  cluster_name    = aws_eks_cluster.epam-eks-cluster.name
  node_group_name = "epam-eks-nodes"
  instance_types  = ["t2.micro"]
  node_role_arn   = aws_iam_role.epam-eks-nodes.arn
  subnet_ids      = [aws_subnet.epam-pub-net-1.id, aws_subnet.epam-pub-net-2.id]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}


# resource "aws_security_group" "sec-nfs" {
#   name        = "sec-nfs"
#   description = "Allow EFS"
#   vpc_id      = "${aws_vpc.vpc.id}"

#   tags {
#     Name = "sec-nfs"
#   }
# }

# resource "aws_security_group_rule" "sec-nfs-in" {
#   type                     = "ingress"
#   from_port                = 2049
#   to_port                  = 2049
#   protocol                 = "tcp"
#   source_security_group_id = "${aws_security_group.sec-ec2.id}"
#   security_group_id        = "${aws_security_group.sec-nfs.id}"
# }

# resource "aws_security_group_rule" "sec-nfs-out" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "${aws_security_group.sec-nfs.id}"
# }

# resource "aws_instance" "web-srv-1" {
#   ami           = "${var.debian_ami_id}"
#   instance_type = "t2.micro"
#   key_name      = "${var.ssh_key_id}"

#   subnet_id = "${aws_subnet.pub-subnet-1.id}"

#   vpc_security_group_ids = ["${aws_security_group.sec-ec2.id}"]

#   user_data = "${file("install_web.sh")}"

#   tags = {
#     Name  = "Web Server 1"
#     Owner = "Ilya Polishchuk"
#   }
# }

# resource "aws_instance" "web-srv-2" {
#   ami           = "${var.debian_ami_id}"
#   instance_type = "t2.micro"
#   key_name      = "${var.ssh_key_id}"

#   subnet_id = "${aws_subnet.pub-subnet-2.id}"

#   vpc_security_group_ids = ["${aws_security_group.sec-ec2.id}"]

#   user_data = "${file("install_web.sh")}"

#   tags = {
#     Name  = "Web Server 2"
#     Owner = "Ilya Polishchuk"
#   }
# }

# resource "aws_lb_target_group" "alb-tg" {
#   health_check {
#     interval            = 10
#     path                = "/"
#     protocol            = "HTTP"
#     timeout             = 3
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }

#   name        = "alb-tg"
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "instance"
#   vpc_id      = "${aws_vpc.vpc.id}"
# }

# resource "aws_lb_target_group_attachment" "alb-tg-1" {
#   target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
#   target_id        = "${aws_instance.web-srv-1.id}"
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "alb-tg-2" {
#   target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
#   target_id        = "${aws_instance.web-srv-2.id}"
#   port             = 80
# }

# resource "aws_lb" "app-lb" {
#   name                       = "app-lb"
#   internal                   = false
#   load_balancer_type         = "application"
#   subnets                    = ["${aws_subnet.pub-subnet-1.id}", "${aws_subnet.pub-subnet-2.id}"]
#   security_groups            = ["${aws_security_group.sec-ec2.id}"]
#   enable_deletion_protection = false
# }

# resource "aws_lb_listener" "list-alb" {
#   load_balancer_arn = "${aws_lb.app-lb.arn}"
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
#   }
# }

# module "rds" {
#   source                              = "terraform-aws-modules/rds/aws"
#   identifier                          = "wordpress"
#   engine                              = "mysql"
#   engine_version                      = "5.7.26"
#   instance_class                      = "db.t2.micro"
#   allocated_storage                   = 5
#   name                                = "wordpress"
#   username                            = "dbadmin"
#   password                            = "AdminPass"
#   port                                = "3306"
#   iam_database_authentication_enabled = true
#   vpc_security_group_ids              = ["${aws_security_group.sec-sql.id}"]
#   subnet_ids                          = ["${aws_subnet.pub-subnet-1.id}", "${aws_subnet.pub-subnet-2.id}"]
#   family                              = "mysql5.7"
#   major_engine_version                = "5.7"
#   version                             = "~> 1.37"
#   maintenance_window                  = "Mon:00:00-Mon:03:00"
#   backup_window                       = "03:00-06:00"
# }

# resource "aws_efs_file_system" "nfs" {
#   creation_token = "nfs-ec2"
#   encrypted      = "false"
# }

# resource "aws_efs_mount_target" "nfs-mt-1" {
#   file_system_id  = "${aws_efs_file_system.nfs.id}"
#   subnet_id       = "${aws_subnet.pub-subnet-1.id}"
#   security_groups = ["${aws_security_group.sec-nfs.id}"]
# }

# resource "aws_efs_mount_target" "nfs-mt-2" {
#   file_system_id  = "${aws_efs_file_system.nfs.id}"
#   subnet_id       = "${aws_subnet.pub-subnet-2.id}"
#   security_groups = ["${aws_security_group.sec-nfs.id}"]
# }

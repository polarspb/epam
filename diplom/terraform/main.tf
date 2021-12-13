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

resource "aws_security_group_rule" "epam-sg-db-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.epam-sg-db.id
}

# ----- EC2 Instances -----

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
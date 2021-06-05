resource "aws_vpc" "vpc-1" {
    cidr_block = "10.10.0.0/16"
    instance_tenancy = "default"

    tags {
        Name = "vpc-1"
        Location = "Saint Petersburg"
    }
}

resource "aws_subnet" "public-sub-1" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    cidr_block = "10.10.1.0/24"
    availability_zone = "us-east-2a"

    tags {
        Name = "public-sub-1"
    }
}

resource "aws_subnet" "public-sub-2" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    cidr_block = "10.10.2.0/24"
    availability_zone = "us-east-2b"

    tags {
        Name = "public-sub-2"
    }
}

resource "aws_internet_gateway" "igw-1" {
    vpc_id = "${aws_vpc.vpc-1.id}"

    tags {
        Name = "igw-01"
    }
}

resource "aws_route_table" "int-rt" {
    vpc_id = "${aws_vpc.vpc-1.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw-1.id}"
    }

    tags {
        Name = "int-rt"
    }
}

resource "aws_route_table_association" "int-rt-1" {
    subnet_id = "${aws_subnet.public-sub-1.id}"
    route_table_id = "${aws_route_table.int-rt.id}"

}

resource "aws_route_table_association" "int-rt-2" {
    subnet_id = "${aws_subnet.public-sub-2.id}"
    route_table_id = "${aws_route_table.int-rt.id}"

}

resource "aws_security_group" "sg-web" {
    name = "vpc_web"
    description = "Allow incoming HTTP & HTTPS connections"
    vpc_id="${aws_vpc.vpc-1.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "web server"
  }
}

resource "aws_security_group" "sg-ssh" {
    name = "vpc_web"
    description = "Allow SSH access"
    vpc_id = "${aws_vpc.vpc-1.id}"

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "ec2-ssh"
  }
}

resource "aws_security_group" "sg-sql" {
  name = "sql-db"
  description = "Allow incoming SQL access"
  vpc_id="${aws_vpc.vpc-1.id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags {
    Name = "mysql"
  }
 }
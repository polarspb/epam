
resource "aws_instance" "web-srv-1" {
  ami           = "ami-089fe97bc00bff7cc"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-sub-1.id}"
  vpc_security_group_ids = [
    "${aws_security_group.sg-ssh.id}",
    "${aws_security_group.sg-web.id}"
  ]
  tags = {
    Name = "web server 1"
    Owner = "Ilya Polishchuk"
  }
}

resource "aws_instance" "web-srv-2" {
  ami           = "ami-089fe97bc00bff7cc"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-sub-2.id}"
  vpc_security_group_ids = [
    "${aws_security_group.sg-ssh.id}",
    "${aws_security_group.sg-web.id}"
  ]
  tags = {
    Name = "web server 2"
    Owner = "Ilya Polishchuk"
  }
}
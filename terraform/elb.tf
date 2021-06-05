resource "aws_elb" "elb-web" {
  name               = "websrv-elb"
#   availability_zones = ["us-east-2a", "us-east-2b"]
  subnets            = ["${aws_subnet.public-sub-1.id}", "${aws_subnet.public-sub-2.id}"]
  security_groups    = ["${aws_security_group.sg-web.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#     listener {
#     instance_port     = 443
#     instance_protocol = "https"
#     lb_port           = 443
#     lb_protocol       = "https"
#     ssl_certificate_id = "arn:aws:acm:us-east-2:XXXXXXXXXXXX:certificate/6016dfa8-5509-4c08-b96a-f3c59a1768c8"
#   }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags = {
    Name = "websrv-elb"
  }
}
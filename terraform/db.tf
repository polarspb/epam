resource "aws_db_subnet_group" "mysql_subnet_group" {
    name       = "mysqlsubgroup"
    subnet_ids = [
    "${aws_subnet.public-sub-1.id}",  
    "${aws_subnet.public-sub-2.id}"
    ]

    tags = {
        Name = "PostgreSQL subnet group"
    }
}

resource "aws_db_instance" "default" {
    identifier = "awsdb"
    engine            = "mysql"
    engine_version    = "5.7.19"
    instance_class    = "db.t2.micro"
    allocated_storage = 5
    name     = "awsdb"
    username = "admin"
    password = "AdminPass!"
    port     = "3306"
    parameter_group_name = "default.mysql5.7"
    iam_database_authentication_enabled = true
    vpc_security_group_ids = [ "${aws_security_group.sg-sql.id}" ]
    db_subnet_group_name = "${aws_db_subnet_group.mysql_subnet_group.id}"
  }
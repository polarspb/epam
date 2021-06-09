## AWS Task

This task create:

1. 2 instance in different AZ
2. VPC
3. 2 different subnets
4. Gateway
5. Route table
6. RDS MySQL
7. EFS (Elastic File System)
8. ALB (Load Balancer)
9. Wordpress

When services created you need:

1. Find in AWS console RDS MySQL name & EFS name
2. Connect to one of the instance
3. Run bash script "conf_first.sh" on the first instance
4. Run bash script "conf_second.sh" on the second instance
5. Configure Wordpress.

P.S. Scripts located on the instance.

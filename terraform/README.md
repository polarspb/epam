## AWS Task
### Create AWS services from Terraform (ver. 0.11.14)

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
2. Connect to the instance 1
3. sudo wget https://raw.githubusercontent.com/polarspb/epam/main/terraform/instance1.sh
4. chmod +x instance1.sh & run script
5. Connect to the instance 2
6. sudo wget https://raw.githubusercontent.com/polarspb/epam/main/terraform/instance2.sh
7. chmod +x instance2.sh & run script
8. Connect to the ALB from browser
9. Configure Wordpress.

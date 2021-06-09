#!/bin/bash
su
apt -y update
apt -y install apache2
echo "Hi It's my Site from $(hostname -f)" > index.html
cp index.html /var/www/html/index.html
service apache2 start
chkconfig apache2 on

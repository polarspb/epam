#!/bin/bash
su
apt -y update
apt -y upgrade
apt -y install nfs-common
apt -y install apache2
apt -y install wordpress
apt -y remove wordpress
wget https://wordpress.org/latest.tar.gz
systemctl restart apache2
systemctl enable apache2

#!/bin/bash
su
apt -y update
apt -y upgrade
apt -y install nfs-common
apt -y install apache2
apt -y install wordpress
apt -y remove wordpress
wget https://raw.githubusercontent.com/polarspb/epam/main/terraform/conf_first.sh
wget https://raw.githubusercontent.com/polarspb/epam/main/terraform/conf_second.sh
chmod +x conf_sys.sh
systemctl restart apache2
systemctl enable apache2

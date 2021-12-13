#!/bin/bash
sudo rm -r /var/www/html/*.*
echo "Please input EFS name (example: fs-fe0bf385): "
read STR
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $STR.efs.us-east-2.amazonaws.com:/ /var/www/html
echo
echo "Download & Unzip File..."
echo
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
echo
echo "Copy Files..."
echo
sudo cp -r wordpress/* /var/www/html/
sudo wget https://raw.githubusercontent.com/polarspb/epam/main/terraform/wp-config.php
echo
echo "Please input RDS base name (example: wordpress.cizydixfugvr.us-east-2.rds.amazonaws.com): "
read STR2
sudo sed -i 's/localhost/'$STR2'/g' wp-config.php
sudo mv wp-config.php /var/www/html/wp-config.php
sudo rm latest.tar.gz
echo
echo "Restart Apache..."
echo
sudo systemctl restart apache2
sudo systemctl enable apache2
echo

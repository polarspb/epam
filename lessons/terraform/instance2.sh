#!/bin/bash
sudo rm -r /var/www/html/*.*
echo -e -n "Please input EFS name (example: fs-fe0bf385): "
read STR
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $STR.efs.us-east-2.amazonaws.com:/ /var/www/html
echo
echo "Restart Apache..."
echo
sudo systemctl restart apache2
sudo systemctl enable apache2
echo

#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
myip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo "<h2> My WebServer with IP: $myip</h2><br> Build by Terraform" | sudo tee /var/www/html/index.html
sudo service apache2 restart

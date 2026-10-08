#!/bin/bash

yum -y install httpd
echo "<h2>WebServer created by terraform </h2>" > /var/www/html/index.html

systemctl enable --now httpd

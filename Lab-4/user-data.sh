#!/bin/bash

yum -y install httpd

echo "Hello" >/var/www/html/index.html
systemctl enable --now httpd


#!/bin/bash
set -Eeuo pipefail

echo "===== AMI cleanup started ====="

# 1. Remove backend environment file containing secrets
if [ -f /var/www/society-app/server/.env ]; then
    rm -f /var/www/society-app/server/.env
    echo "Backend .env file removed"
else
    echo "Backend .env file not found"
fi

# 2. Stop and disable MongoDB
systemctl disable --now mongod

# 3. Stop and disable Nginx
systemctl disable --now nginx

echo "===== AMI cleanup completed ====="

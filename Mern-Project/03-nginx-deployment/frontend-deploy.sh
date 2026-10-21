
#!/bin/bash
set -Eeuo pipefail

APP_DIR="/var/www/society-app"
CLIENT_DIR="$APP_DIR/client"
DIST_DIR="$CLIENT_DIR/dist"

echo "===== Frontend deployment started ====="

# 1. Verify the existing frontend directory
if [ ! -f "$CLIENT_DIR/package.json" ]; then
    echo "ERROR: $CLIENT_DIR/package.json not found"
    exit 1
fi

# 2. Create production environment configuration
cat > "$CLIENT_DIR/.env.production" <<'EOF'
VITE_API_URL=https://devopsai.fun/api/v1
VITE_API_URL_ROOT=https://devopsai.fun
EOF

chown society:society "$CLIENT_DIR/.env.production"
chmod 600 "$CLIENT_DIR/.env.production"

# 3. Install Nginx and SELinux utilities
dnf install -y nginx policycoreutils-python-utils

# 4. Install frontend dependencies and build
cd "$CLIENT_DIR"
npm install
npm run build

# 5. Verify production build
if [ ! -f "$DIST_DIR/index.html" ]; then
    echo "ERROR: Frontend build did not create dist/index.html"
    exit 1
fi

# 6. Set ownership and directory/file permissions
chown -R nginx:nginx "$DIST_DIR"
chmod 711 /var
chmod 755 /var/www "$APP_DIR" "$CLIENT_DIR"
find "$DIST_DIR" -type d -exec chmod 755 {} \;
find "$DIST_DIR" -type f -exec chmod 644 {} \;

# 7. Configure SELinux to allow Nginx to read frontend files
if semanage fcontext -l | grep -Fq "$DIST_DIR"; then
    semanage fcontext -m -t httpd_sys_content_t \
        "$DIST_DIR(/.*)?"
else
    semanage fcontext -a -t httpd_sys_content_t \
        "$DIST_DIR(/.*)?"
fi

restorecon -Rv "$DIST_DIR"

# 8. Install the supplied Nginx virtual-host configuration
install -m 644 /tmp/society.conf \
    /etc/nginx/conf.d/society.conf

# Avoid a conflicting packaged default virtual host
if [ -f /etc/nginx/conf.d/default.conf ]; then
    mv /etc/nginx/conf.d/default.conf \
       /etc/nginx/conf.d/default.conf.disabled
fi

# 9. Validate and restart Nginx
nginx -t
systemctl enable nginx
systemctl restart nginx

# 10. Local verification on EC2
test -f "$DIST_DIR/index.html"
curl -fsS -H "Host: devopsai.fun" \
    http://127.0.0.1/ >/dev/null

echo "===== Frontend deployment completed ====="

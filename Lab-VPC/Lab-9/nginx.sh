
#!/bin/bash

# Exit if any command fails
set -e

echo "===================================="
echo " Installing and Configuring Nginx"
echo "===================================="

# Check root privileges ----
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script using sudo."
    exit 1
fi

# Update package ------
echo "Updating packages..."
apt-get update

# Install Nginx
echo "Installing Nginx..."
apt-get install -y nginx

# Enable and start Nginx
echo "Starting Nginx service..."
systemctl enable --now nginx

# Configure custom web page
echo "Creating custom web page..."

cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Nginx Web Server</title>
</head>
<body>
    <h1>Welcome to Nginx!</h1>
    <h2>Configured on Ubuntu Linux</h2>
    <p>Web server installed successfully.</p>
</body>
</html>
EOF

# Validate Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Reload Nginx
systemctl reload nginx

# Display service status
echo "===================================="
echo "Nginx Installation Completed!"
echo "===================================="

systemctl --no-pager --full status nginx

echo "Test locally using:"
echo "curl http://localhost"

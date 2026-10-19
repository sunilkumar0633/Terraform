#!/bin/bash
set -Eeuo pipefail
umask 077

# Log all output and show the failing line if a command fails
exec > >(tee -a /var/log/user-data-backend.log) 2>&1
trap 'rc=$?; echo "ERROR: Script failed at line ${LINENO}, exit code ${rc}"; exit "$rc"' ERR

echo "===== Society application setup started ====="

# 1. Install required packages
dnf install -y git curl jq unzip

# 2. Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

echo "Node: $(node --version)"
echo "NPM: $(npm --version)"

# 3. Install MongoDB 7.0 on RHEL 9
cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

dnf install -y mongodb-org
systemctl enable --now mongod
systemctl is-active --quiet mongod

echo "MongoDB is running"

# 4. Install AWS CLI v2
curl -fsSL \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

rm -f /tmp/awscliv2.zip
rm -rf /tmp/aws

# 5. Detect region using IMDSv2
TOKEN=$(curl -fsS -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

AWS_REGION=$(curl -fsS \
  -H "X-aws-ec2-metadata-token: ${TOKEN}" \
  "http://169.254.169.254/latest/meta-data/placement/region")

export AWS_DEFAULT_REGION="$AWS_REGION"
echo "AWS region: ${AWS_REGION}"

# 6. Create application user
if ! id society >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash society
fi

# 7. Fix parent directory permissions BEFORE running as society
mkdir -p /var/www
chmod 755 /var/www

# 8. Clone application repository
if [ ! -d /var/www/society-app/.git ]; then
  git clone \
    https://github.com/sunilkumar0633/Society-management-System.git \
    /var/www/society-app
else
  echo "Repository already exists"
fi

# Ensure society can traverse and read its application directories
chown -R society:society /var/www/society-app
chmod 755 /var/www/society-app

if [ ! -d /var/www/society-app/server ]; then
  echo "ERROR: Backend directory /var/www/society-app/server not found"
  exit 1
fi

chmod 755 /var/www/society-app/server

# 9. Retrieve application settings from Secrets Manager
SECRET_ID="society-app/production"
SECRET_FILE="/run/society-app-secret.json"

aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text > "$SECRET_FILE"

chmod 600 "$SECRET_FILE"

if ! jq -e 'type == "object"' "$SECRET_FILE" >/dev/null; then
  echo "ERROR: Secret must be a valid JSON object"
  rm -f "$SECRET_FILE"
  exit 1
fi

# 10. Create backend .env
# Use local MongoDB, not MongoDB Atlas
cd /var/www/society-app/server

jq -er '
  .MONGODB_URI = "mongodb://127.0.0.1:27017/society"
  | to_entries[]
  | "\(.key)=\(.value | tostring | @json)"
' "$SECRET_FILE" > .env

chown society:society .env
chmod 600 .env

rm -f "$SECRET_FILE"

echo "Backend environment file created"

# 11. Install dependencies as society
runuser -u society -- \
  bash -c 'cd /var/www/society-app/server && npm install'

# 12. Install PM2 and allow society to execute it
npm install -g pm2@7.0.4

PM2_ROOT="$(npm root -g)/pm2"
PM2_RUNTIME="$(command -v pm2-runtime)"

if [ ! -f "${PM2_ROOT}/bin/pm2-runtime" ] || [ -z "$PM2_RUNTIME" ]; then
  echo "ERROR: PM2 Runtime executable not found"
  exit 1
fi

chmod -R a+rX "$PM2_ROOT"

if ! runuser -u society -- test -x "$PM2_RUNTIME"; then
  echo "ERROR: society user cannot execute PM2 Runtime"
  exit 1
fi

# 13. Create systemd service
cat > /etc/systemd/system/society-backend.service <<EOF
[Unit]
Description=Society Management Node.js Backend
Wants=network-online.target mongod.service
After=network-online.target mongod.service

[Service]
Type=simple
User=society
WorkingDirectory=/var/www/society-app/server
Environment=HOME=/home/society
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=${PM2_RUNTIME} start app.js --name society-backend
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 14. Enable and start backend
systemctl daemon-reload
systemctl enable --now society-backend

echo "===== Society application setup completed ====="

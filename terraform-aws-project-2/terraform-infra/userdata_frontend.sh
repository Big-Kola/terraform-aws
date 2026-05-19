#!/bin/bash
dnf update -y
dnf install -y nginx nodejs git

cd /home/ec2-user
git clone --depth 1 https://github.com/Big-Kola/terraform-aws-project-2.git app 2>/tmp/git_err.log || echo "git clone failed: $(cat /tmp/git_err.log)"

cd /home/ec2-user/app/frontend
npm install 2>/tmp/npm_err.log || echo "npm install failed: $(cat /tmp/npm_err.log)"

echo "PORT=3000" > /etc/goal-tracker-frontend.env
echo "BACKEND_URL=http://${alb_dns}" >> /etc/goal-tracker-frontend.env

cat > /etc/systemd/system/goal-tracker-frontend.service << 'SERVICEEOF'
[Unit]
Description=Goal Tracker Frontend
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/ec2-user/app/frontend
ExecStart=/usr/bin/env node /home/ec2-user/app/frontend/server.js
EnvironmentFile=/etc/goal-tracker-frontend.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable goal-tracker-frontend
systemctl start goal-tracker-frontend

cat > /etc/nginx/conf.d/default.conf << 'NGINXEOF'
server {
    listen 80;
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINXEOF

systemctl restart nginx

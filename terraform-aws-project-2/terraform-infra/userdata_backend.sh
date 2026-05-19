#!/bin/bash
dnf update -y
dnf install -y git golang

cd /home/ec2-user
git clone --depth 1 https://github.com/Big-Kola/terraform-aws-project-2.git app 2>/tmp/git_err.log || echo "git clone failed: $(cat /tmp/git_err.log)"

cd /home/ec2-user/app/backend
go build -o /usr/local/bin/goal-tracker-backend . 2>/tmp/go_err.log || echo "go build failed: $(cat /tmp/go_err.log)"

echo "DB_HOST=${db_host}" > /etc/goal-tracker-backend.env
echo "DB_PORT=5432" >> /etc/goal-tracker-backend.env
echo "DB_USERNAME=postgres" >> /etc/goal-tracker-backend.env
echo "DB_PASSWORD=${db_password}" >> /etc/goal-tracker-backend.env
echo "DB_NAME=goalsdb" >> /etc/goal-tracker-backend.env
echo "SSL=require" >> /etc/goal-tracker-backend.env
echo "PORT=8080" >> /etc/goal-tracker-backend.env

cat > /etc/systemd/system/goal-tracker-backend.service << 'SERVICEEOF'
[Unit]
Description=Goal Tracker Backend
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/goal-tracker-backend.env
ExecStart=/usr/local/bin/goal-tracker-backend
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable goal-tracker-backend
systemctl start goal-tracker-backend

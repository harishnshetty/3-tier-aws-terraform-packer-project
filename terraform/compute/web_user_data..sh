#!/bin/bash
set -e

yum update -y
yum install -y git nginx

# Clone the repo
cd /tmp
rm -rf 3-tier-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-terraform-packer-project.git

# Deploy frontend files
cp -r 3-tier-terraform-packer-project/application_code/web_files/* /var/www/html/

# Configure Nginx to serve frontend + proxy API to backend ALB
cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name _;

        root /var/www/html;
        index index.html;

        location /health {
            try_files \$uri /health.php;
        }

        location / {
            try_files \$uri /index.html;
        }

        # Proxy API requests to backend ALB
        location /api/ {
            proxy_pass http://${app_alb_dns};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

systemctl enable nginx
systemctl restart nginx

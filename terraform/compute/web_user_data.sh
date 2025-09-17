#!/bin/bash
set -e

yum update -y
amazon-linux-extras enable php8.0
yum install -y git nginx php php-fpm php-mysqlnd php-json

# Clone the repo
cd /tmp
rm -rf 3-tier-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-terraform-packer-project.git

# Deploy frontend files
cp -r 3-tier-terraform-packer-project/application_code/web_files/* /var/www/html/

# Configure PHP-FPM
cat > /etc/php-fpm.d/www.conf <<EOF
[www]
user = nginx
group = nginx
listen = /var/run/php-fpm/php-fpm.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
EOF

# Configure Nginx to serve frontend + proxy API to backend ALB + process PHP
cat > /etc/nginx/nginx.conf <<'EOF'
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
        index index.html index.php;

        # PHP processing
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }

        location /health {
            try_files $uri /health.php;
        }

        location / {
            try_files $uri /index.html;
        }

        # Proxy API requests to backend ALB
        location /api/ {
            proxy_pass http://${app_alb_dns};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# Set permissions
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Enable and start services
systemctl enable nginx
systemctl enable php-fpm
systemctl restart nginx
systemctl restart php-fpm
EOF
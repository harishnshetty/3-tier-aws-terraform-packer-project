#!/bin/bash
set -e

echo "===== Frontend User Data Script Started ====="

# Update and install Apache + PHP + Proxy modules
yum update -y
yum install -y httpd php php-json git mod_proxy mod_proxy_http -y

# Clone the repo fresh
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Deploy frontend files
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/web_files/* /var/www/html/

# Apache virtual host configuration
# Apache virtual host configuration
cat > /etc/httpd/conf.d/frontend.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        FallbackResource /index.html
    </Directory>

    # Pass environment variables
    SetEnv APP_ALB_DNS ${backend_alb_dns}
    SetEnv PROJECT_NAME ${project_name}
    SetEnv ENVIRONMENT ${environment}

    # Proxy API requests to backend ALB
    ProxyPass "/api/" "http://${backend_alb_dns}/api/"
    ProxyPassReverse "/api/" "http://${backend_alb_dns}/api/"
    
    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>
</VirtualHost>
EOF


# Make sure proxy modules are enabled
echo "LoadModule proxy_module modules/mod_proxy.so"     >  /etc/httpd/conf.modules.d/00-proxy.conf
echo "LoadModule proxy_http_module modules/mod_proxy_http.so" >> /etc/httpd/conf.modules.d/00-proxy.conf

# Fix permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Enable and start Apache
systemctl enable httpd
systemctl restart httpd

echo "===== Frontend User Data Script Completed Successfully ====="
echo "🌐 Backend ALB DNS: ${app_alb_dns}"

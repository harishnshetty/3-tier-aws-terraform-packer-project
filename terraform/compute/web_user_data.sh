#!/bin/bash
set -e

# Update and install Apache + PHP
yum update -y
yum install -y httpd php php-mysqlnd php-json git

# Clone the repo
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Deploy frontend files
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/web_files/* /var/www/html/

# Configure Apache with environment variables and proxy
cat > /etc/httpd/conf.d/frontend.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        FallbackResource /index.html
    </Directory>

    # Pass environment variables
    SetEnv APP_ALB_DNS ${app_alb_dns}
    SetEnv PROJECT_NAME ${project_name}
    SetEnv ENVIRONMENT ${environment}

    # Proxy API requests to backend ALB - FIXED CONFIGURATION
    ProxyPass /api/ http://${app_alb_dns}/api/
    ProxyPassReverse /api/ http://${app_alb_dns}/api/
    
    # Handle PHP files
    <FilesMatch \.php$>
        SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>
</VirtualHost>
EOF

# Enable proxy modules
echo "LoadModule proxy_module modules/mod_proxy.so" >> /etc/httpd/conf.modules.d/00-proxy.conf
echo "LoadModule proxy_http_module modules/mod_proxy_http.so" >> /etc/httpd/conf.modules.d/00-proxy.conf
echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so" >> /etc/httpd/conf.modules.d/00-proxy.conf

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Enable and start Apache
systemctl enable httpd
systemctl restart httpd

echo "✅ Frontend setup complete with Apache!"
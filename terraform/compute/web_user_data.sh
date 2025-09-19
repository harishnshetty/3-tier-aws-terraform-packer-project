#!/bin/bash
set -e

# Update and install Apache + PHP
yum update -y
yum install -y httpd php php-json git jq

# Clone the repo
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Try to get ALB DNS from Terraform output or AWS metadata
APP_ALB_DNS=""
TF_OUTPUT_FILE="/tmp/tf_output.json"

# Method 1: Check if Terraform output file exists
if [ -f "/path/to/terraform/outputs.json" ]; then
    APP_ALB_DNS=$(jq -r '.app_alb_dns_name.value' "/path/to/terraform/outputs.json")
fi

# Method 2: Use AWS CLI to find ALB by tags
if [ -z "$APP_ALB_DNS" ]; then
    APP_ALB_DNS=$(aws elbv2 describe-load-balancers --region ap-south-1 --query "LoadBalancers[?contains(LoadBalancerName, 'app')].DNSName" --output text)
fi

# Method 3: Fallback to default if still not found
if [ -z "$APP_ALB_DNS" ]; then
    APP_ALB_DNS="app-alb.internal"
fi

# Deploy frontend files
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/web_files/* /var/www/html/

# Create config.php with the ALB DNS
cat > /var/www/html/config.php << EOF
<?php
// Auto-generated configuration file
define('APP_ALB_DNS', 'http://$APP_ALB_DNS');
define('PROJECT_NAME', 'three-tier-app');
define('ENVIRONMENT', 'production');
?>
EOF

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
    SetEnv APP_ALB_DNS $APP_ALB_DNS
    SetEnv PROJECT_NAME three-tier-app
    SetEnv ENVIRONMENT production

    # Proxy API requests to backend ALB
    ProxyPass /api/ http://$APP_ALB_DNS/api/
    ProxyPassReverse /api/ http://$APP_ALB_DNS/api/
    
    # Handle PHP files
    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>
</VirtualHost>
EOF

# Enable proxy modules
cat > /etc/httpd/conf.modules.d/00-proxy.conf << 'EOF'
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Enable and start Apache
systemctl enable httpd
systemctl restart httpd

echo "✅ Frontend setup complete with Apache!"
echo "🌐 Backend ALB DNS: $APP_ALB_DNS"
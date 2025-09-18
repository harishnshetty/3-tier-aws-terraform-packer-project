#!/bin/bash
set -e

# Update and install Apache + PHP
yum update -y
yum install -y httpd php php-json git curl

# Clone the repo
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Deploy frontend files
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/web_files/* /var/www/html/

# Create a test script to debug the backend connection
cat > /var/www/html/debug-backend.php << 'EOF'
<?php
header('Content-Type: text/plain');
$alb_dns = getenv("APP_ALB_DNS") ?: "undefined";
echo "APP_ALB_DNS: " . $alb_dns . "\n\n";

// Test backend connection
$backend_url = "http://" . $alb_dns . "/api/health";
echo "Testing: " . $backend_url . "\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $backend_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: " . $http_code . "\n";
echo "Response: " . $response . "\n";
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
    SetEnv APP_ALB_DNS ${app_alb_dns}
    SetEnv PROJECT_NAME ${project_name}
    SetEnv ENVIRONMENT ${environment}

    # Proxy API requests to backend ALB - VERBOSE LOGGING
    ProxyPass /api/ http://${app_alb_dns}/api/ retry=0
    ProxyPassReverse /api/ http://${app_alb_dns}/api/
    
    # Log proxy requests for debugging
    LogLevel debug
    ErrorLog /var/log/httpd/proxy_error.log
    CustomLog /var/log/httpd/proxy_access.log combined
</VirtualHost>
EOF

# Enable proxy modules
echo "LoadModule proxy_module modules/mod_proxy.so" > /etc/httpd/conf.modules.d/00-proxy.conf
echo "LoadModule proxy_http_module modules/mod_proxy_http.so" >> /etc/httpd/conf.modules.d/00-proxy.conf

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Enable and start Apache
systemctl enable httpd
systemctl restart httpd

# Test the configuration
echo "Testing backend connection..."
sleep 3
curl -s http://localhost/debug-backend.php

echo "✅ Frontend setup complete! Check /debug-backend.php for connection issues."
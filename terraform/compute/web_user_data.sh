#!/bin/bash
set -e

# Update and install dependencies
dnf update -y
dnf install -y httpd php

# Enable and start Apache
systemctl enable httpd
systemctl start httpd

# Clone the repo
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Deploy frontend files
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/web_files/* /var/www/html/

# Create environment configuration endpoint
cat > /var/www/html/env-config.php << 'EOL'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Get backend URL from Terraform variables
$backendUrl = 'http://${app_alb_dns}/api';

echo json_encode([
    'backendUrl' => $backendUrl,
    'environment' => '${environment}',
    'project' => '${project_name}',
    'timestamp' => date('c')
]);
?>
EOL

# Create a health check endpoint
cat > /var/www/html/health.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Frontend Health Check</title>
    <meta name="robots" content="noindex,nofollow">
</head>
<body>
    <h1>Frontend Health Check</h1>
    <p>Status: OK</p>
    <p>Server: <?php echo gethostname(); ?></p>
    <p>Time: <?php echo date('Y-m-d H:i:s'); ?></p>
    <p>Environment: <?php echo getenv('ENVIRONMENT') ?: 'development'; ?></p>
</body>
</html>
EOL

# Update HTML with correct backend URL
sed -i "s|http://internal-three-tier-app-app-alb-1059148255.ap-south-1.elb.amazonaws.com/api|http://${app_alb_dns}/api|g" /var/www/html/index.html

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to allow CORS
cat > /etc/httpd/conf.d/cors.conf << 'EOL'
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization"

# Handle preflight requests
RewriteEngine On
RewriteCond %{REQUEST_METHOD} OPTIONS
RewriteRule ^(.*)$ $1 [R=200,L]
EOL

# Enable mod_rewrite and mod_headers
sed -i '/LoadModule rewrite_module/s/^#//g' /etc/httpd/conf.modules.d/00-base.conf
sed -i '/LoadModule headers_module/s/^#//g' /etc/httpd/conf.modules.d/00-base.conf

# Restart Apache to apply all configurations
systemctl restart httpd

echo "🎉 Frontend setup completed successfully!"
echo "🌐 Server: $(hostname)"
echo "📊 Environment: ${environment}"
echo "🏷️ Project: ${project_name}"
echo "🔗 Backend API: http://${app_alb_dns}/api"
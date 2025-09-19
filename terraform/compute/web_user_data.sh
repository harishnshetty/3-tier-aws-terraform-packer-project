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

$backendUrl = 'http://${app_alb_dns}/api';

# Create environment configuration endpoint
cat > /var/www/html/env-config.php << EOF
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Get backend URL from Terraform variables
\$backendUrl = 'http://${app_alb_dns}/api';

echo json_encode([
    'backendUrl' => \$backendUrl,
    'environment' => '${environment}',
    'project' => '${project_name}',
    'timestamp' => date('c')
]);
?>
EOF

# Create a dynamic configuration file
cat > /var/www/html/config.js << EOF
// Auto-generated configuration
window.APP_CONFIG = {
    API_BASE_URL: 'http://${app_alb_dns}/api',
    ENVIRONMENT: '${environment}',
    PROJECT_NAME: '${project_name}',
    TIMESTAMP: '$(date -Iseconds)'
};
EOF

# Update the meta tag in HTML with the actual ALB DNS from Terraform
sed -i "s|http://APP_ALB_DNS_PLACEHOLDER/api|http://${app_alb_dns}/api|g" /var/www/html/index.html

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to allow CORS
cat > /etc/httpd/conf.d/cors.conf << 'EOL'
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
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
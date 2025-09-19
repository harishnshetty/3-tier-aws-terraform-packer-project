#!/bin/bash
set -e

# Update and install dependencies
apt-get update -y
apt-get install -y apache2 php git curl

# Enable and start Apache
systemctl enable apache2
systemctl start apache2

# Clone the repo
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Deploy frontend files
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/web_files/* /var/www/html/

# Backend URL from Terraform variable
backendUrl="http://${app_alb_dns}/api"

# Create environment configuration endpoint
cat > /var/www/html/env-config.php << EOF
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

\$backendUrl = '${backendUrl}';

echo json_encode([
    'backendUrl' => \$backendUrl,
    'environment' => '${environment}',
    'project' => '${project_name}',
    'timestamp' => date('c')
]);
?>
EOF

# Create a dynamic JavaScript config file
cat > /var/www/html/config.js << EOF
// Auto-generated configuration
window.APP_CONFIG = {
    API_BASE_URL: '${backendUrl}',
    ENVIRONMENT: '${environment}',
    PROJECT_NAME: '${project_name}',
    TIMESTAMP: '$(date -Iseconds)'
};
EOF

# Update index.html meta tag if placeholder exists
if grep -q "APP_ALB_DNS_PLACEHOLDER" /var/www/html/index.html; then
    sed -i "s|http://APP_ALB_DNS_PLACEHOLDER/api|${backendUrl}|g" /var/www/html/index.html
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to allow CORS
cat > /etc/apache2/conf-available/cors.conf << EOF
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
EOF

a2enmod headers
a2enmod rewrite
a2enconf cors

# Restart Apache to apply all configurations
systemctl restart apache2

echo "🎉 Frontend setup completed successfully!"
echo "🌐 Server: $(hostname)"
echo "📊 Environment: ${environment}"
echo "🏷️ Project: ${project_name}"
echo "🔗 Backend API: ${backendUrl}"

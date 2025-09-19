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

# Create a dynamic configuration file that will be injected by the server
cat > /var/www/html/config.php << EOF
<?php
header('Content-Type: application/javascript');
header('Access-Control-Allow-Origin: *');

\$app_alb_dns = '${app_alb_dns}';
\$environment = '${environment}';
\$project_name = '${project_name}';

echo "window.APP_CONFIG = {
    API_BASE_URL: 'http://' . \$app_alb_dns . '/api',
    ENVIRONMENT: '" . \$environment . "',
    PROJECT_NAME: '" . \$project_name . "',
    TIMESTAMP: '" . date('c') . "'
};";
?>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to allow CORS
cat > /etc/httpd/conf.d/cors.conf << 'EOL'
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
EOL

# Restart Apache to apply all configurations
systemctl restart httpd

echo "🎉 Frontend setup completed successfully!"
echo "🌐 Server: $(hostname)"
echo "📊 Environment: ${environment}"
echo "🏷️ Project: ${project_name}"
echo "🔗 Backend API: http://${app_alb_dns}/api"
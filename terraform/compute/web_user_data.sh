#!/bin/bash
set -e

# Update and install dependencies
dnf update -y
dnf install -y httpd

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

# Create a health check endpoint for frontend auto-detection
cat > /var/www/html/health.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
    <meta name="robots" content="noindex,nofollow">
</head>
<body>
    <h1>Frontend Health Check</h1>
    <p>Status: OK</p>
    <p>Server: $(hostname)</p>
    <p>Time: $(date)</p>
</body>
</html>
EOL

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to allow CORS for API discovery
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
echo "🔗 Backend API will be auto-discovered by the frontend"
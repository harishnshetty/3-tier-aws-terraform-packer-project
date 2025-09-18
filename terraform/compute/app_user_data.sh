#!/bin/bash
set -e

# Update and install dependencies
dnf update -y
dnf install -y php php-mysqlnd php-json php-pdo git httpd composer

# Enable and start Apache
systemctl enable httpd
systemctl start httpd

# Install official MySQL client
wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
dnf install -y mysql80-community-release-el9-1.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf install -y mysql-community-client

# Clone the repo
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Deploy backend PHP app directly to /var/www/html
rm -rf /var/www/html/*
cp -r 3-tier-aws-terraform-packer-project/application_code/app_files/* /var/www/html/

# Copy SQL file for database initialization
cp /tmp/3-tier-aws-terraform-packer-project/packer/backend/appdb.sql /tmp/appdb.sql

# Database initialization function (RUNS IN FOREGROUND)
initialize_database() {
    echo "🔄 Initializing database..."
    
    # Database connection parameters (from Terraform template)
    DB_HOST="${db_host}"
    DB_NAME="${db_name}"
    DB_USER="${db_user}"
    DB_PASSWORD="${db_password}"
    
    # Wait for RDS to be ready (with timeout)
    echo "⏳ Waiting for RDS to be available..."
    for i in {1..30}; do
        if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" 2>/dev/null; then
            echo "✅ Database connection successful!"
            
            # Import the SQL schema
            echo "📦 Importing database schema..."
            if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" < /tmp/appdb.sql; then
                echo "🎉 Database initialization complete!"
                return 0
            else
                echo "❌ Failed to import database schema!"
                return 1
            fi
        fi
        echo "📡 Database not ready yet (attempt $i/30), retrying in 10 seconds..."
        sleep 10
    done
    
    echo "❌ Timeout waiting for database connection!"
    return 1
}

# Run database initialization (in foreground)
initialize_database

# Configure Apache with environment variables
# Configure Apache with environment variables
echo "📝 Configuring Apache environment..."
cat > /etc/httpd/conf.d/app.conf << 'EOL'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        # Use FallbackResource instead of complex rewrite rules
        FallbackResource /index.php
    </Directory>

    # Pass environment variables from Terraform
    SetEnv DB_HOST ${db_host}
    SetEnv DB_USERNAME ${db_user}
    SetEnv DB_PASSWORD ${db_password}
    SetEnv DB_NAME ${db_name}
    SetEnv ENVIRONMENT ${environment}
    SetEnv PROJECT_NAME ${project_name}
</VirtualHost>
EOL

# Also create .env file as backup
echo "📝 Creating .env file..."
cat > /var/www/html/.env << EOL
DB_HOST=${db_host}
DB_USERNAME=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
ENVIRONMENT=${environment}
PROJECT_NAME=${project_name}
EOL

# Set proper permissions
chown apache:apache /var/www/html/.env
chmod 640 /var/www/html/.env

# Install PHP dependencies if composer.json exists (safe method)
if [ -f /var/www/html/composer.json ]; then
    echo "📦 Installing PHP dependencies..."
    # Set proper home directory for composer
    export HOME=/home/ec2-user
    export COMPOSER_HOME=/home/ec2-user/.composer
    mkdir -p $COMPOSER_HOME
    chown ec2-user:ec2-user $COMPOSER_HOME
    
    # Run composer as ec2-user
    sudo -u ec2-user bash -c "
        cd /var/www/html
        export COMPOSER_ALLOW_SUPERUSER=1
        composer install --no-dev --optimize-autoloader --no-interaction
    "
fi

# Restart Apache to apply all configurations
echo "🔄 Restarting Apache..."
systemctl restart httpd

# Test the configuration
echo "🧪 Testing API configuration..."
sleep 5

# Test health endpoint
if curl -s http://localhost/api/health > /dev/null; then
    echo "✅ API health check passed!"
else
    echo "❌ API health check failed!"
    echo "Checking Apache error logs:"
    tail -20 /var/log/httpd/error_log
fi

# Test database connection through API
if curl -s http://localhost/api/db-test > /dev/null; then
    echo "✅ Database connection test passed!"
else
    echo "⚠️ Database connection test may have failed (check API)"
fi

echo "🎉 Backend setup completed successfully!"
echo "🌐 Server: $(hostname)"
echo "📊 Environment: ${environment}"
echo "🏷️ Project: ${project_name}"
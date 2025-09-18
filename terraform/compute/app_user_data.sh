#!/bin/bash
set -e

# Update and install dependencies
dnf update -y
dnf install -y php php-mysqlnd php-json git httpd composer

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
    
    # Database connection parameters
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

# Install PHP dependencies if composer.json exists (FIXED - run as ec2-user)
if [ -f /var/www/html/composer.json ]; then
    echo "📦 Installing PHP dependencies..."
    # Run composer as ec2-user with proper environment
    sudo -u ec2-user bash -c "cd /var/www/html && COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader"
fi

# Apache vhost for the app
cat > /etc/httpd/conf.d/app.conf <<EOL
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

# Restart Apache
systemctl restart httpd

echo "✅ Backend setup complete!"
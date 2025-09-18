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

# Install PHP dependencies if composer.json exists
if [ -f /var/www/html/composer.json ]; then
    cd /var/www/html
    composer install --no-dev --optimize-autoloader
fi

# Copy SQL file for database initialization
cp /tmp/3-tier-aws-terraform-packer-project/packer/backend/appdb.sql /tmp/appdb.sql

# Database initialization function
initialize_database() {
    echo "🔄 Initializing database..."
    
    # Database connection parameters (passed from Terraform)
    DB_HOST="${db_host}"
    DB_NAME="${db_name}"
    DB_USER="${db_user}"
    DB_PASSWORD="${db_password}"
    
    # Wait for RDS to be ready
    echo "⏳ Waiting for RDS to be available..."
    until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" 2>/dev/null; do
        echo "📡 Database not ready yet, retrying in 10 seconds..."
        sleep 10
    done
    
    echo "✅ Database connection successful!"
    
    # Import the SQL schema
    echo "📦 Importing database schema..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" < /tmp/appdb.sql
    
    echo "🎉 Database initialization complete!"
}

# Run database initialization in background (non-blocking)
initialize_database &

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
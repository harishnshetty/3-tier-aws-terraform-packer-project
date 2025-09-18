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
rm -rf 3-tier-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-terraform-packer-project.git

# Deploy backend PHP app directly to /var/www/html
rm -rf /var/www/html/*
cp -r 3-tier-terraform-packer-project/application_code/app_files/* /var/www/html/

# Install PHP dependencies if composer.json exists
if [ -f /var/www/html/composer.json ]; then
    cd /var/www/html
    composer install --no-dev --optimize-autoloader
fi

# Set DB connection details via environment variables
cat > /etc/profile.d/app_env.sh <<EOF
export DB_HOST="${db_host}"
export DB_USERNAME="${db_username}"
export DB_PASSWORD="${db_password}"
export DB_NAME="appdb"
EOF
chmod 600 /etc/profile.d/app_env.sh

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

# Import database schema if appdb.sql exists
if [ -f /var/www/html/appdb.sql ]; then
    mysql -h ${db_host} -u ${db_username} -p${db_password} appdb < /var/www/html/appdb.sql || true
fi

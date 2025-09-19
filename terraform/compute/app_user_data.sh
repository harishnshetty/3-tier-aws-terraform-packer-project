#!/bin/bash
set -e

# -----------------------------
# Update and install dependencies
# -----------------------------
apt-get update -y
apt-get install -y python3 python3-pip git curl

# -----------------------------
# Install Python packages
# -----------------------------
pip3 install --upgrade pip
pip3 install flask mysql-connector-python gunicorn

# -----------------------------
# Clone the backend repo
# -----------------------------
cd /tmp
rm -rf 3-tier-aws-terraform-packer-project
git clone https://github.com/harishnshetty/3-tier-aws-terraform-packer-project.git

# Copy app files
rm -rf /opt/app
mkdir -p /opt/app
cp -r 3-tier-aws-terraform-packer-project/application_code/app_files/* /opt/app/

# -----------------------------
# Create database configuration file
# -----------------------------
cat > /opt/app/db_config.py << EOF
DB_CONFIG = {
    "host": "${db_host}",
    "user": "${db_user}",
    "password": "${db_password}",
    "database": "${db_name}"
}
EOF

chown -R ubuntu:ubuntu /opt/app
chmod -R 750 /opt/app

# -----------------------------
# Create Python DB initialization script
# -----------------------------
cat > /opt/app/db_init.py << EOF
import mysql.connector
from db_config import DB_CONFIG

conn = mysql.connector.connect(**DB_CONFIG)
cursor = conn.cursor()

# Create tables if not exist
cursor.execute("""
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
)
""")
cursor.execute("""
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2)
)
""")

# Insert initial data (ignore duplicates)
cursor.execute("""
INSERT IGNORE INTO users (id, name, email) VALUES
(1, 'Alice', 'alice@example.com'),
(2, 'Bob', 'bob@example.com')
""")
cursor.execute("""
INSERT IGNORE INTO products (id, name, price) VALUES
(1, 'Product1', 10.50),
(2, 'Product2', 20.00)
""")

conn.commit()
cursor.close()
conn.close()
EOF

# Run DB initialization
echo "🔄 Initializing database..."
python3 /opt/app/db_init.py
echo "✅ Database initialized successfully!"

# -----------------------------
# Create systemd service for Flask API
# -----------------------------
cat > /etc/systemd/system/backend.service << EOF
[Unit]
Description=Python Flask Backend API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/app
ExecStart=/usr/local/bin/gunicorn -w 3 -b 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable backend.service
systemctl start backend.service

# -----------------------------
# Wait for API to become healthy
# -----------------------------
echo "⏳ Waiting for backend API to start..."
for i in {1..20}; do
    if curl -s http://localhost:5000/api/users > /dev/null; then
        echo "✅ Backend API is up and running!"
        break
    fi
    echo "Waiting 5 seconds..."
    sleep 5
done

# -----------------------------
# Output status
# -----------------------------
echo "🎉 Backend setup completed successfully!"
echo "🌐 Server: $(hostname)"
echo "📊 Environment: ${environment}"
echo "🏷️ Project: ${project_name}"
echo "🔗 API URL: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):5000"

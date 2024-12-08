#!/bin/bash

# Step 1: Install Essential Packages, Docker, and Tools
echo "Installing essential packages and tools..."

# Install jq
sudo apt update
sudo apt install -y jq apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Verify Docker installation
docker --version

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Step 2: Install Docker Compose
echo "Installing Docker Compose..."

# Download the latest Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version

# Step 3: Create docker-compose.yaml File
echo "Setting up docker-compose.yaml..."

cat <<EOF > docker-compose.yaml
version: '3.3'

services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    ports:
      - "8081:8081"
      - "5000:5000"
    volumes:
      - nexus-data:/nexus-data
    environment:
      - INSTALL4J_ADD_VM_PARAMS=-Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -Djava.util.prefs.userRoot=/nexus-data/javaprefs
    networks:
      - nexus-network

  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./registry.conf:/etc/nginx/conf.d/registry.conf
      - ./certs:/etc/ssl/
    networks:
      - nexus-network

volumes:
  nexus-data:
    driver: local

networks:
  nexus-network:
    driver: bridge
EOF

# Step 4: Obtain SSL Certificates
echo "Obtaining SSL certificates with Certbot..."
sudo apt install -y certbot

# Replace with your actual domain
DOMAIN="registry.seyedmahdisheikh.ir"
sudo certbot certonly --standalone -d $DOMAIN

# Copy SSL certificates to certs directory
mkdir -p certs
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./certs/certificate.crt
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./certs/private.key

# Step 5: Create registry.conf for Nginx
echo "Creating Nginx configuration file..."

cat <<EOF > registry.conf
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/ssl/certificate.crt;
    ssl_certificate_key /etc/ssl/private.key;

    client_max_body_size 1G;

    location / {
        proxy_pass http://nexus:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Step 6: Start Docker Compose
echo "Starting Docker Compose..."
docker-compose down
docker-compose up -d

# Step 7: Get the Nexus Admin Password
echo "Fetching Nexus admin password..."
docker exec -it nexus cat /nexus-data/admin.password
echo "Nexus is set up. Use the above password with username 'admin' to log in."

echo "Setup complete!"

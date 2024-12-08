# Private Registry Nexus

# Option 1 : Install Automaticly :

1. `git clone git@github.com:mahdiambow/devops_private_registry.git`
2. `cd devops_private_registry`
3. `chmod +x install.sh`
4. `sudo ./install.sh`

# Option 2 : Install Manual :

## Setp 1 : Install Essential Package And Tools And Docker

1 . Install jq :

`sudo apt install jq
`

2 . Install Dependencies:

`sudo apt install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common`

3 . Add Docker's Official GPG Key :

## Adding Docker's Official GPG Key

Run the following command to add Docker's GPG key:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

4 . Add Docker Repository :

`echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
`

5 . Install Docker :

`sudo apt update
`

`sudo apt install docker-ce docker-ce-cli containerd.io`

6 . Verify Docker Installation:

`sudo docker --version`

7 . Start and Enable Docker:

`sudo systemctl start docker`

`sudo systemctl enable docker
`

## Step 2: Install Docker Compose

1 . Download Docker Compose :

`sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
`

2 . Apply Executable Permissions :

`sudo chmod +x /usr/local/bin/docker-compose
`

3 . Verify Docker Compose Installation :

`docker-compose --version
`

## Step 3: Create `docker-compose.yaml` File

```plaintext
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
      - "443:443
    volumes:
      - ./registry.conf:/etc/nginx/conf.d/registry.conf
      - ./certs/:/etc/ssl/
    networks:
      - nexus-network

volumes:
  nexus-data:
    driver: local

networks:
  nexus-network:
    driver: bridge

```

## Step 4: Create SSL Certification

1 . Install Certbot :

`sudo apt update`

`sudo apt install certbot
`

2 . Generate SSL Certificates :

`sudo certbot certonly --standalone -d registry.exampale.ir
`

3 . Locate Generated Certificates:

Certificate: `/etc/letsencrypt/live/registry.seyedmahdisheikh.ir/fullchain.pem`

Private Key: `/etc/letsencrypt/live/registry.seyedmahdisheikh.ir/privkey.pem`

## Step 5: Create `registry.conf` File

```plaintext
server {
    listen 80;
    server_name registry.seyedmahdisheikh.ir;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name registry.seyedmahdisheikh.ir;

    ssl_certificate /etc/letsencrypt/live/registry.seyedmahdisheikh.ir/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/registry.seyedmahdisheikh.ir/privkey.pem;

    client_max_body_size 1G;

    location / {
        proxy_pass http://nexus:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

```

## Step 8: Start Docker Compose

`docker-compose down`

`docker-compose up -d
`

## Step 9: Get The Password of Nexus :

`sudo docker exec -it nexus /bin/bash`

`cat /nexus-data/admin.password`

Username : Admin

<!-- You can either generate self-signed certificates (for testing purposes) or obtain a valid certificate from a trusted Certificate Authority (CA) like Let's Encrypt.

# Option 1: Generate a Self-Signed Certificate (for testing)

If you just need it for testing and don’t have a domain with a valid certificate, you can generate a self-signed SSL certificate:

mkdir -p ./certs
cd ./certs

# Generate a private key

openssl genpkey -algorithm RSA -out private.key -pkeyopt rsa_keygen_bits:2048

# Generate a self-signed certificate (valid for 365 days)

openssl req -new -key private.key -out certificate.csr

#

openssl x509 -req -days 365 -in certificate.csr -signkey private.key -out certificate.crt

sudo certbot certonly --standalone -d registry.sananetco.com

sudo cp /etc/letsencrypt/live/registry.sananetco.com/fullchain.pem ./certs/certificate.crt

sudo cp /etc/letsencrypt/live/registry.sananetco.com/privkey.pem ./certs/private.key

chmod 644 ./certs/certificate.crt

chmod 644 ./certs/private.key

# -->

# Private Registry Nexus

# Step 1: Obtain SSL Certificates

You can either generate self-signed certificates (for testing purposes) or obtain a valid certificate from a trusted Certificate Authority (CA) like Let's Encrypt.

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

#

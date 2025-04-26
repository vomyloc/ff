# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Install N8N
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e N8N_HOST=n8nfanal.anhbotdeptrai.site \  # Replace with your domain
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

  # Install Nginx
sudo apt install nginx -y

# Install Certbot (for SSL)
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d n8nfanal.anhbotdeptrai.site

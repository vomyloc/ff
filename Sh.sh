    sudo docker run -d --restart unless-stopped -it \
    --name n8n \
    -p 5678:5678 \
    -e N8N_HOST="n8nfanal.anhbotdeptrai.site" \
    -e WEBHOOK_TUNNEL_URL="https://n8nfanal.anhbotdeptrai.site/" \
    -e WEBHOOK_URL="https://n8nfanal.anhbotdeptrai.site/" \
    -v ~/.n8n:/root/.n8n \
    n8nio/n8n


server {
    listen 80;
    server_name n8nfanal.anhbotdeptrai.site; // subdomain.your-domain.com if you have a subdomain

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

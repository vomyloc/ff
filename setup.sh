sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y
wget -O- https://nginx.org/keys/nginx_signing.key | gpg --dearmor     | tee /etc/apt/trusted.gpg.d/nginx.gpg > /dev/null
mkdir -m 600 /root/.gnupg
gpg --dry-run --quiet --import --import-options import-show /etc/apt/trusted.gpg.d/nginx.gpg
echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx"     | tee /etc/apt/sources.list.d/nginx.list
sudo apt update
sudo apt purge nginx nginx-common nginx-full nginx-core
sudo apt install nginx
nginx -v
systemctl enable nginx
systemctl start nginx
#######Cài nginx#####
mkdir /etc/nginx/{modules-available,modules-enabled,sites-available,sites-enabled,snippets}
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat > /etc/nginx/nginx.conf << 'EOL'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}


#mail {
#	# See sample authentication script at:
#	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
# 
#	# auth_http localhost/auth.php;
#	# pop3_capabilities "TOP" "USER";
#	# imap_capabilities "IMAP4rev1" "UIDPLUS";
# 
#	server {
#		listen     localhost:110;
#		protocol   pop3;
#		proxy      on;
#	}
# 
#	server {
#		listen     localhost:143;
#		protocol   imap;
#		proxy      on;
#	}
#}

EOL

nginx -t
mkdir -p /etc/systemd/system/nginx.service.d/
echo -e "[Service]\nRestart=always\nRestartSec=10s" > /etc/systemd/system/nginx.service.d/restart.conf
systemctl daemon-reload
systemctl enable nginx
systemctl start nginx
systemctl restart nginx
cd /home
mkdir n8n.anhbotdeptrai.site
#####Cấu hình domain nginx ####
sudo tee /etc/nginx/conf.d/n8n.anhbotdeptrai.site.conf > /dev/null << 'EOL'
server {
    listen 80;
    listen [::]:80;
    server_name n8n.anhbotdeptrai.site;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name n8n.anhbotdeptrai.site;
    ssl_certificate /etc/nginx/ssl/n8n.anhbotdeptrai.site/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/n8n.anhbotdeptrai.site/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    #ssl_stapling on;
    #ssl_stapling_verify on;

    # Enable gzip compression for text-based resources
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;


	
	add_header Content-Security-Policy "frame-ancestors *";
	add_header 'Access-Control-Allow-Origin' '*';
	add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
	add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
	add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';

    # Increase the body size limit to accommodate large uploads
    client_max_body_size 15G;

	
    # Proxy settings for the application server
    location / {
	
		proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
		proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 16 64k;
        proxy_buffer_size 128k;
        client_max_body_size 10M;
        proxy_set_header X-Forwarded-Server $host;

        proxy_pass_request_headers on;
        proxy_max_temp_file_size 0;
        proxy_connect_timeout 900;
        proxy_send_timeout 900;
        proxy_read_timeout 900;

        proxy_busy_buffers_size 256k;
        proxy_temp_file_write_size 256k;
        proxy_intercept_errors on;
    }
}
EOL

#Tao thu muc SSL
sudo mkdir -p /etc/nginx/ssl/n8n.anhbotdeptrai.site/
sudo tee /etc/nginx/ssl/n8n.anhbotdeptrai.site/certificate.crt > /dev/null << 'EOL'
-----BEGIN CERTIFICATE-----
MIIEyDCCA7CgAwIBAgIUQwXMew/cnRQaa2z7C5AXMK+tkOIwDQYJKoZIhvcNAQEL
BQAwgYsxCzAJBgNVBAYTAlVTMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTQw
MgYDVQQLEytDbG91ZEZsYXJlIE9yaWdpbiBTU0wgQ2VydGlmaWNhdGUgQXV0aG9y
aXR5MRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMRMwEQYDVQQIEwpDYWxpZm9ybmlh
MB4XDTI1MDQyNjEyNTkwMFoXDTQwMDQyMjEyNTkwMFowYjEZMBcGA1UEChMQQ2xv
dWRGbGFyZSwgSW5jLjEdMBsGA1UECxMUQ2xvdWRGbGFyZSBPcmlnaW4gQ0ExJjAk
BgNVBAMTHUNsb3VkRmxhcmUgT3JpZ2luIENlcnRpZmljYXRlMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsHw3OwL6ZHRs34yeBZmNKIP+ReoNH5gKgS8+
qMqk2UZQyYnpbO8TurZHd7dpthm2NEpVb38iFVFq2lfUaAEofik7tZCPHJpcXRhx
DGtng2CItGFgpw9GQ0IRFsIy6KukEYbZww7oCBI2lUfbYH1qC6whPISqHpeDMg49
U2AkdEFggLBLFsBWIanriBiLprqUgc0sr1MyWwICjyafdTONBJv/3NrgbBPYuLCc
R38irNN/d5PTDyQn0FuxnmQGPM3ip2JigxkNdQThaiiMsuIQhKvyewTgKSEW1yVK
Fhchdaz2uzZF2hr23RXrR2a0xyDONgq3FQtu0qM0C41Oa9YU2wIDAQABo4IBSjCC
AUYwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
ATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBT016KGH3UwzphsynNSDg1rkodcgzAf
BgNVHSMEGDAWgBQk6FNXXXw0QIep65TbuuEWePwppDBABggrBgEFBQcBAQQ0MDIw
MAYIKwYBBQUHMAGGJGh0dHA6Ly9vY3NwLmNsb3VkZmxhcmUuY29tL29yaWdpbl9j
YTBLBgNVHREERDBCghQqLmFuaGJvdGRlcHRyYWkuc2l0ZYISYW5oYm90ZGVwdHJh
aS5zaXRlghZuOG4uYW5oYm90ZGVwdHJhaS5zaXRlMDgGA1UdHwQxMC8wLaAroCmG
J2h0dHA6Ly9jcmwuY2xvdWRmbGFyZS5jb20vb3JpZ2luX2NhLmNybDANBgkqhkiG
9w0BAQsFAAOCAQEAf5RRDDn948TBzSFgmDVFTuLVJmfPp4tD1xXLpJ9V3+flUltU
FDUmTO56Qs3xYe6mF78RfLxoIsivxRxJaZlw3+q7Sx3KIzEHK7s8yDXesSTU5f+x
VGW7KyOHr6DZ9H7Dnt1ntrCBJvi3xa6VlquoYhlDkYCXmCqc74erfTi5TpMCwoIY
5gYilcE0BZk+R8LXAKYHGKCLc6nWo8iR4GFS3SKblvE5r8DNE7KkxuJpuq3neXow
IhkVJrM1DmNYqi3FJaJGAvkrDA/OSpqmtswFn4ESuM3veu2UUCQfWgnGfLzoXx9f
DzKocZR95OJcy4npNqsOrDDm6gYKLpuHF8tvqA==
-----END CERTIFICATE-----
EOL
sudo tee /etc/nginx/ssl/n8n.anhbotdeptrai.site/private.key > /dev/null << 'EOL'
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCwfDc7AvpkdGzf
jJ4FmY0og/5F6g0fmAqBLz6oyqTZRlDJiels7xO6tkd3t2m2GbY0SlVvfyIVUWra
V9RoASh+KTu1kI8cmlxdGHEMa2eDYIi0YWCnD0ZDQhEWwjLoq6QRhtnDDugIEjaV
R9tgfWoLrCE8hKoel4MyDj1TYCR0QWCAsEsWwFYhqeuIGIumupSBzSyvUzJbAgKP
Jp91M40Em//c2uBsE9i4sJxHfyKs0393k9MPJCfQW7GeZAY8zeKnYmKDGQ11BOFq
KIyy4hCEq/J7BOApIRbXJUoWFyF1rPa7NkXaGvbdFetHZrTHIM42CrcVC27SozQL
jU5r1hTbAgMBAAECggEAOQE+U7zQBP+IJSMF7bgd3K7ZxFpnt8ND7VtFyX5/BcFN
GfQGZk3I2R/EcNpY9l1SuYwjEXsGls0wDuucq6VoH2wRIcHaP/pqCBX7ee/9RPW6
4kyry/pGjzX5UBkVGYtLWO/uSa94ahb783b82KtZxABq0eHmEzCMS3BHBbXBwJzN
ip35YyYTEnR5LAA/s1D6j5+FZFZVH1wWiK+t7ZTZojYd0M807WD1A8c+SzEFeDmX
pBDXjHGrFGO8VPAM6DF2JqNMMKbhqevyWKyedl/yruSHOI0E6bE98AF6exGbcYeq
JaKq84dIs6CXcVgGYYR6kiwuqSxdHK+KGBcgP4ixxQKBgQDn1GO9At3BTVK4PSBe
N2afQQ2gjUCP6v48cxlfdJPlzpceBSDt5K5MKQMnrYyrPKBGV8Xg5gdkJugHMSw8
gRWGJQPgZ9nijtn3fJluQfiw9ZFMG4YVbGynWdlBR7cDeTsDBo6WlyOiGigI1KKL
jNQdlHkxhNhGms9mmTNbatMfJwKBgQDC4qo3+Ixe38xx2j9YTipjZ6Ctv5+YnYgr
CDW7PlhfMBJ2el7qzNavOvQu3xHGR0sUPk3pSuq9T+oKKYnU8OJvs0mq0dIQEnoG
nLVyifbZyIVtdEyUlhB9PJeR+CnMnqpMmdcNtwxYwmfaJBGObNVt7xivo1sFCaQD
DJ5hxZptLQKBgF8owivygj33VE4F4URrLzeNh19wu6CXj/YWNMMG4jKBY2xSJJsh
tB3U89OUnFopj4xwOOxA36XPhox1Nbg8MC6ZAQda+YfSpUu+HGiysbdJhXOdFKO0
lsD204PFQS0u1Pc/+MV9koXWgLpnNbVcgDEIIdsesXwBzcJKflc2+SQfAoGAN4uR
Bmjh4TyaMa0Jtup4bGKhykO+gioMIG+zmM2ZNHAoIvqXyQZe/gyogh90GnZBcOCd
JiwDIbgANatHLJkHgNyx12z8GTaa7v2FPcMSx1m+pcaq+QKYaol1jdYUW8yxLyn9
wFv2uemW3fa/xj9AyZeHCrBdhd8Mjw3uqmE+tXUCgYAbRNPX/v9jjogii2ISt8ne
eEeMPQWihZu6h2IaF/+EM0otegN0z5UXK1vYHhvFrL2tQRqA2D+9Z4hccOlkGeas
E1jCMMYmc1WoFh+TLCZhFrN6bYZEy8xfzmkuw7KFY1MNQNItCXqD8c1H1hJz3KN6
o1OxDd+7C6el0pMm/7lPdw==
-----END PRIVATE KEY-----
EOL
systemctl daemon-reload
systemctl restart nginx
service nginx restart
# Khởi động lại dịch vụ Nginx để áp dụng cấu hình
systemctl restart nginx
cd /home/n8n.anhbotdeptrai.site
# Khởi động lại dịch vụ Nginx để áp dụng cấu hình
systemctl restart nginx
# Cập nhật danh sách gói và cài đặt software-properties-common
sudo apt update
sudo apt install software-properties-common

#Cài mout ổ đĩa
sudo apt-get install nginx cifs-utils -y
sudo service nginx restart
cd /home/n8n.anhbotdeptrai.site


sudo apt update

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install docker-ce -y

sudo apt update
sudo apt install -y docker-compose-plugin

#sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

#sudo chmod +x /usr/local/bin/docker-compose

sudo systemctl start docker
sudo systemctl enable docker
sleep 5

sudo tee /home/n8n.anhbotdeptrai.site/docker-compose.yml > /dev/null << 'EOL'
services:
  postgres:
    image: postgres:latest
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n_zen
      POSTGRES_PASSWORD: n8n_pass
      POSTGRES_DB: n8n_db
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=Admin
      - N8N_BASIC_AUTH_PASSWORD=zendeptrai
      - N8N_HOST=n8n.anhbotdeptrai.site
      - WEBHOOK_URL=https://n8n.anhbotdeptrai.site/
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n_db
      - DB_POSTGRESDB_USER=n8n_zen
      - DB_POSTGRESDB_PASSWORD=n8n_pass
    depends_on:
      - postgres
    volumes:
      - ./n8n_data:/home/node/.n8n
EOL

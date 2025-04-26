#!/bin/bash

# --- Cấu hình của bạn ---
# !! THAY THẾ TÊN MIỀN CỦA BẠN NẾU CẦN !!
N8N_DOMAIN="n8n.anhbotdeptrai.site"
N8N_HTTPS_URL="https://${N8N_DOMAIN}/"
# !! THAY THẾ 'your_email@example.com' BẰNG EMAIL CỦA BẠN !!
# Email này được dùng cho thông báo từ Let's Encrypt và đồng ý điều khoản dịch vụ.
LETSENCRYPT_EMAIL="tuanghulon@gmail.com"
# ---------------------

# Kiểm tra xem email đã được thay thế chưa
if [ "${LETSENCRYPT_EMAIL}" == "your_email@example.com" ]; then
    echo "--------- ❌ Lỗi cấu hình: Vui lòng chỉnh sửa script và thay thế 'your_email@example.com' bằng địa chỉ email thật của bạn! -----------"
    exit 1
fi


# --- Thiết lập Cơ bản (Docker và Volume) ---
echo "--------- 🟢 Bắt đầu cài đặt docker -----------"
# Cập nhật danh sách gói
sudo apt update -y # Thêm -y để tự động đồng ý
# Cài đặt các gói cần thiết
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
# Thêm khóa GPG chính thức của Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg # Cách mới hơn cho Ubuntu 20.04+
# Thêm kho lưu trữ Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null # Cách mới hơn
# Cập nhật lại sau khi thêm repo
sudo apt update -y
# Kiểm tra chính sách gói Docker (tùy chọn)
apt-cache policy docker-ce
# Cài đặt Docker CE
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin # Cài đặt thêm các công cụ mới
echo "--------- 🔴 Hoàn thành cài đặt docker -----------"

echo "--------- 🟢 Bắt đầu tạo thư mục volume -----------"
# Di chuyển về thư mục home
cd ~
# Tạo thư mục volume
mkdir -p vol_n8n # Sử dụng -p để không báo lỗi nếu thư mục đã tồn tại
# Thiết lập quyền sở hữu và truy cập phù hợp cho container n8n (user ID 1000 là user node trong image n8n)
sudo chown -R 1000:1000 vol_n8n
sudo chmod -R 755 vol_n8n
echo "--------- 🔴 Hoàn thành tạo thư mục volume -----------"

echo "--------- 🟢 Bắt đầu tạo file compose.yaml và chạy docker compose -----------"

# Export biến CURR_DIR để sử dụng trong compose.yaml
export CURR_DIR=$(pwd)

cat <<EOL > compose.yaml
services:
  svr_n8n:
    image: n8nio/n8n
    container_name: cont_n8n
    environment:
      # Bật secure cookie khi sử dụng HTTPS qua reverse proxy
      - N8N_SECURE_COOKIE=true
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      # Thiết lập URL và Host sử dụng tên miền HTTPS của bạn
      - N8N_EDITOR_BASE_URL=${N8N_HTTPS_URL}
      - WEBHOOK_URL=${N8N_HTTPS_URL}
      - N8N_HOST=${N8N_DOMAIN}
      - N8N_DEFAULT_BINARY_DATA_MODE=filesystem
      - N8N_MCP_ENABLED=true
      - N8N_MCP_MODE=server
      # Các biến môi trường khác của n8n có thể thêm vào đây nếu cần

    ports:
      # Mở cổng 80 trên host (VPS) và liên kết với cổng 5678 của container n8n.
      # Reverse Proxy (Nginx/Caddy) sẽ lắng nghe cổng 443 (HTTPS) và chuyển tiếp traffic đến cổng 80 này trên VPS.
      # Điều này cho phép reverse proxy xử lý SSL và tên miền, sau đó gửi yêu cầu HTTP nội bộ đến n8n.
      - "80:5678"

    volumes:
      # Gắn kết thư mục volume đã tạo để lưu trữ dữ liệu n8n
      - ${CURR_DIR}/vol_n8n:/home/node/.n8n

# Định nghĩa biến CURR_DIR để sử dụng trong volumes
# Biến này đã được export bên ngoài trước khi chạy docker compose
EOL

# Chạy docker compose up ở chế độ nền (-d)
# Sử dụng sudo -E để giữ lại biến môi trường CURR_DIR
sudo -E docker compose up -d

echo "--------- 🔴 Hoàn thành thiết lập container n8n -----------"

# --- Cài đặt và Cấu hình Reverse Proxy (Nginx) và SSL (Certbot) ---
echo "--------- 🟢 Bắt đầu cài đặt và cấu hình Reverse Proxy (Nginx) và SSL (Certbot) -----------"

# Cài đặt Nginx và Certbot plugin cho Nginx
sudo apt update -y
sudo apt install -y nginx certbot python3-certbot-nginx

# Tạo file cấu hình Nginx cho tên miền trong sites-available
NGINX_CONF="/etc/nginx/sites-available/${N8N_DOMAIN}"
sudo cat <<EOL > ${NGINX_CONF}
server {
    listen 80;
    listen [::]:80;
    server_name ${N8N_DOMAIN};

    # Phần cấu hình chuyển hướng HTTP sang HTTPS và SSL sẽ được Certbot tự động thêm vào/chỉnh sửa sau.
    # Ban đầu chỉ cần cấu hình proxy pass.

    location / {
        # Proxy các yêu cầu đến container n8n thông qua cổng 80 trên host (VPS)
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Cấu hình cần thiết cho WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Cấu hình thời gian chờ (tùy chọn)
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
EOL

# Kích hoạt cấu hình Nginx bằng cách tạo symbolic link từ sites-available sang sites-enabled
sudo ln -s ${NGINX_CONF} /etc/nginx/sites-enabled/

# Kiểm tra cú pháp cấu hình Nginx
echo "--------- 🟢 Kiểm tra cú pháp cấu hình Nginx -----------"
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "--------- ❌ Lỗi: Cấu hình Nginx không hợp lệ. Vui lòng kiểm tra thủ công: sudo nginx -t -----------"
    # Không thoát hẳn mà vẫn cho người dùng cơ hội sửa và chạy lại Certbot/Nginx sau
    # exit 1 # Nếu muốn script dừng lại khi có lỗi Nginx
fi

# Tải lại cấu hình Nginx để áp dụng file cấu hình mới
echo "--------- 🟢 Tải lại cấu hình Nginx -----------"
sudo systemctl reload nginx

# Chạy Certbot để lấy chứng chỉ SSL và cấu hình Nginx
# !! ĐẢM BẢO DNS CHO '${N8N_DOMAIN}' ĐÃ TRỎ VỀ IP CỦA VPS NÀY TRƯỚC KHI CHẠY LỆNH NÀY !!
# !! ĐẢM BẢO CỔNG 80 VÀ 443 ĐÃ MỞ TRÊN FIREWALL CỦA VPS !!
echo "--------- 🟢 Bắt đầu lấy chứng chỉ SSL với Certbot cho tên miền '${N8N_DOMAIN}' -----------"
echo "!! LƯU Ý QUAN TRỌNG: Certbot cần tên miền của bạn phải trỏ DNS chính xác đến VPS này và cổng 80/443 phải mở trên Firewall để xác thực. !!"

# Chạy Certbot ở chế độ không tương tác. Nó sẽ cố gắng cấu hình Nginx và lấy chứng chỉ.
# Nếu Certbot thành công, nó sẽ tự động thêm cấu hình SSL và chuyển hướng HTTP sang HTTPS vào file cấu hình Nginx.
sudo certbot --nginx -d "${N8N_DOMAIN}" --non-interactive --agree-tos --email "${LETSENCRYPT_EMAIL}" --redirect --staple-ocsp --preferred-challenges http --hsts --uir --keep-until-expiring # Thêm --keep-until-expiring để không cập nhật nếu chứng chỉ còn hạn

if [ $? -ne 0 ]; then
    echo "--------- ❌ Lỗi: Certbot không lấy được hoặc không cấu hình được chứng chỉ SSL. -----------"
    echo "   Vui lòng kiểm tra:"
    echo "   - Cấu hình DNS cho '${N8N_DOMAIN}' đã trỏ đúng về IP của VPS chưa."
    echo "   - Firewall của VPS đã mở cổng 80 (HTTP) và 443 (HTTPS) chưa."
    echo "   - Kiểm tra lại cú pháp cấu hình Nginx: sudo nginx -t"
    echo "   - Chạy Certbot thủ công để xem lỗi chi tiết: sudo certbot --nginx -d ${N8N_DOMAIN} --email ${LETSENCRYPT_EMAIL} --preferred-challenges http"
    echo "   Nếu bạn đã sửa lỗi và chạy Certbot thủ công thành công, nhớ tải lại cấu hình Nginx: sudo systemctl reload nginx"
    # Script sẽ tiếp tục nhưng truy cập qua HTTPS sẽ không hoạt động cho đến khi bạn sửa lỗi Certbot
else
    # Tải lại cấu hình Nginx sau khi Certbot đã cập nhật (nếu Certbot chạy thành công)
    echo "--------- 🟢 Tải lại cấu hình Nginx sau khi Certbot đã cập nhật -----------"
    sudo systemctl reload nginx
    echo "--------- 🔴 Hoàn thành cài đặt và cấu hình Reverse Proxy (Nginx) và SSL (Certbot) -----------"
    echo ""
    echo "--------- ✅ Thiết lập n8n với tên miền '${N8N_DOMAIN}' và HTTPS đã hoàn tất (với điều kiện DNS và Firewall đã đúng). -----------"
    echo ""
    echo "Vui lòng kiểm tra trong trình duyệt tại:"
    echo "${N8N_HTTPS_URL}"
    echo ""
    echo "Chứng chỉ SSL từ Let's Encrypt sẽ tự động được gia hạn bởi hệ thống."
fi

echo "--------- Thông tin kiểm tra hữu ích: -----------"
echo "- Trạng thái container n8n: sudo docker ps | grep cont_n8n"
echo "- Logs của container n8n: sudo docker logs cont_n8n"
echo "- Trạng thái dịch vụ Nginx: sudo systemctl status nginx"
echo "- Trạng thái dịch vụ Certbot Timer (gia hạn tự động): sudo systemctl status certbot.timer"


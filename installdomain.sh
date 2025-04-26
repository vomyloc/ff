#!/bin/bash

# Định nghĩa tên miền n8n của bạn
N8N_DOMAIN="n8n.anhbotdeptrai.site"
N8N_HTTPS_URL="https://${N8N_DOMAIN}/"

echo "--------- 🟢 Bắt đầu cài đặt docker -----------"
# Cập nhật danh sách gói
sudo apt update
# Cài đặt các gói cần thiết
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
# Thêm khóa GPG chính thức của Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Thêm kho lưu trữ Docker
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
# Kiểm tra chính sách gói Docker (tùy chọn)
apt-cache policy docker-ce
# Cài đặt Docker CE
sudo apt install -y docker-ce
echo "--------- 🔴 Hoàn thành cài đặt docker -----------"

echo "--------- 🟢 Bắt đầu tạo thư mục volume -----------"
# Di chuyển về thư mục home
cd ~
# Tạo thư mục volume
mkdir vol_n8n
# Thiết lập quyền sở hữu và truy cập phù hợp cho container n8n
sudo chown -R 1000:1000 vol_n8n
sudo chmod -R 755 vol_n8n
echo "--------- 🔴 Hoàn thành tạo thư mục volume -----------"

echo "--------- 🟢 Bắt đầu tạo file compose.yaml và chạy docker compose -----------"

# Export biến CURR_DIR để sử dụng trong compose.yaml
export CURR_DIR=$(pwd)

# Tạo nội dung file compose.yaml trực tiếp trong script
# Sử dụng heredoc để ghi nội dung multi-line vào file
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
echo ""
echo "Container n8n đã được khởi động."
echo "Để truy cập n8n bằng tên miền '${N8N_DOMAIN}', bạn cần thực hiện thêm 2 bước quan trọng:"
echo ""
echo "1.  **Cấu hình DNS:** Truy cập trình quản lý DNS của tên miền '${N8N_DOMAIN}' và tạo (hoặc chỉnh sửa) bản ghi A để trỏ tên miền này đến địa chỉ IP công khai của VPS của bạn."
echo ""
echo "2.  **Cấu hình Reverse Proxy (Nginx/Caddy) và SSL:** Cài đặt một reverse proxy trên VPS để lắng nghe các kết nối đến tên miền '${N8N_DOMAIN}' trên cổng 80 (HTTP) và cổng 443 (HTTPS). Reverse proxy này sẽ xử lý chứng chỉ SSL (ví dụ: dùng Certbot để lấy Let's Encrypt miễn phí) và chuyển tiếp các yêu cầu đến container n8n thông qua cổng 80 trên VPS host mà container đang lắng nghe."
echo "    (Tham khảo hướng dẫn cấu hình Reverse Proxy đã được cung cấp trước đó)."
echo ""
echo "Sau khi DNS và Reverse Proxy đã được thiết lập và cập nhật đầy đủ, bạn có thể truy cập n8n tại:"
echo "${N8N_HTTPS_URL}"

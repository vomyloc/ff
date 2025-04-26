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


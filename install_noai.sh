#!/bin/bash

echo "--------- 🟢 Bắt đầu cài đặt docker -----------"
# Cập nhật danh sách gói
sudo apt update -y # Thêm -y để tự động đồng ý
# Cài đặt các gói cần thiết
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
# Thêm khóa GPG chính thức của Docker (cách mới hơn cho Ubuntu 20.04+)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# Thêm kho lưu trữ Docker (cách mới hơn)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Cập nhật lại sau khi thêm repo
sudo apt update -y
# Cài đặt Docker CE và các công cụ liên quan
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin # Cài đặt thêm các công cụ mới
echo "--------- 🔴 Hoàn thành cài đặt docker -----------"

echo "--------- 🟢 Bắt đầu tạo thư mục volume -----------"
# Di chuyển về thư mục home
cd ~
# Tạo thư mục volume (sử dụng -p để không báo lỗi nếu đã tồn tại)
mkdir -p vol_n8n
# Thiết lập quyền sở hữu và truy cập phù hợp cho container n8n (user ID 1000 là user node trong image n8n)
sudo chown -R 1000:1000 vol_n8n
sudo chmod -R 755 vol_n8n
echo "--------- 🔴 Hoàn thành tạo thư mục volume -----------"

echo "--------- 🟢 Bắt đầu tải file compose.yaml và chạy docker compose -----------"
# Tải file compose.yaml đã được cấu hình sẵn cho tên miền
wget https://raw.githubusercontent.com/vomyloc/ff/refs/heads/main/compose_noai.yaml -O compose.yaml

# Export biến CURR_DIR để sử dụng trong compose.yaml (cần thiết vì compose file sử dụng biến này)
export CURR_DIR=$(pwd)

# Biến EXTERNAL_IP không được sử dụng trong file compose_noai.yaml đã tải, nên không cần export.
# Dòng sau được chú thích lại/xóa bỏ:
# export EXTERNAL_IP=http://"$(hostname -I | cut -f1 -d' ')"

# Chạy docker compose up ở chế độ nền (-d)
# Sử dụng sudo -E để giữ lại biến môi trường CURR_DIR
sudo -E docker compose up -d

echo "--------- 🔴 Hoàn thành việc triển khai container n8n! -----------"
echo ""
echo "Container n8n đã được triển khai thành công bằng file compose_noai.yaml đã tải."
echo "Theo file cấu hình đó, n8n được thiết lập để chạy với tên miền và HTTPS:"
echo "https://n8n.anhbotdeptrai.site/"
echo ""
echo "Để có thể truy cập n8n qua tên miền này, bạn cần thực hiện 2 bước cấu hình bên ngoài script:"
echo "1.  **Cấu hình DNS:** Đảm bảo bạn đã tạo hoặc chỉnh sửa bản ghi A cho tên miền 'n8n.anhbotdeptrai.site' trong trình quản lý DNS của bạn để nó trỏ đến địa chỉ IP công khai của VPS này."
echo "2.  **Cấu hình Reverse Proxy và SSL (HTTPS):** File compose lắng nghe trên cổng 80 của VPS. Bạn cần cài đặt và cấu hình một Reverse Proxy (như Nginx hoặc Caddy) trên VPS. Reverse Proxy này sẽ lắng nghe trên cổng 443 (HTTPS) cho tên miền 'n8n.anhbotdeptrao.site',"
echo "    xử lý chứng chỉ SSL (ví dụ: dùng Certbot để lấy Let's Encrypt miễn phí), và chuyển tiếp traffic đến cổng 80 trên VPS (nơi container n8n đang lắng nghe)."
echo ""
echo "Sau khi DNS và Reverse Proxy/SSL được thiết lập đầy đủ và cập nhật, bạn có thể truy cập n8n tại:"
echo "https://n8n.anhbotdeptrai.site/"
echo ""
echo "Nếu gặp lỗi, bạn có thể kiểm tra logs của container n8n bằng lệnh: sudo docker logs cont_n8n"


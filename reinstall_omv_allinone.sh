#!/bin/bash
set -e
echo "========================================================"
echo " OMV ALL-IN-ONE FIXED: Reinstall OMV7 + XFCE + Docker + Pi-hole + Parsec"
echo " - OMV web ports: HTTP 8080 / HTTPS 4333"
echo " - Pi-hole: DNS 8053 / Web 9080"
echo "========================================================"

# --- Chuẩn bị môi trường
apt clean
apt update -y
apt install -y wget curl gnupg lsb-release apt-transport-https ca-certificates sudo nano

echo "[INFO] Sửa lỗi GPG key OMV..."
rm -f /etc/apt/trusted.gpg.d/openmediavault* /usr/share/keyrings/openmediavault-archive-keyring.gpg
wget -O - https://packages.openmediavault.org/public/archive.key | gpg --dearmor | tee /usr/share/keyrings/openmediavault-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public shaitan main" > /etc/apt/sources.list.d/openmediavault.list

apt update -y

echo "[INFO] Gỡ OMV cũ và cài lại nginx..."
systemctl stop nginx || true
apt purge -y nginx nginx-common nginx-full openmediavault* || true
apt install -y nginx openmediavault

echo "[INFO] Cấu hình lại OMV..."
omv-confdbadm populate || true
omv-rpc -u admin "webgui.set" '{"port":8080,"enablessl":true,"sslport":4333}'
systemctl restart nginx openmediavault-engined

# --- Cài XFCE desktop và XRDP
echo "[INFO] Cài XFCE + XRDP..."
apt install -y xfce4 xfce4-terminal lightdm xorgxrdp xrdp dbus-x11
echo xfce4-session > /etc/skel/.xsession
echo xfce4-session > /root/.xsession
update-alternatives --set x-session-manager /usr/bin/startxfce4
systemctl enable xrdp
systemctl restart xrdp

# --- Cài Google Chrome
echo "[INFO] Cài Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
apt install -y /tmp/chrome.deb || apt -f install -y

# --- Cài Code::Blocks + Zoom
echo "[INFO] Cài Code::Blocks + Zoom..."
apt install -y codeblocks
wget https://zoom.us/client/latest/zoom_amd64.deb -O /tmp/zoom.deb
apt install -y /tmp/zoom.deb || apt -f install -y

# --- Cài Parsec (.deb)
echo "[INFO] Cài Parsec..."
wget https://builds.parsecgaming.com/package/parsec-linux.deb -O /tmp/parsec.deb
apt install -y /tmp/parsec.deb || apt -f install -y

# --- Cài Docker & Pi-hole (Docker)
echo "[INFO] Cài Docker & Pi-hole..."
apt install -y docker.io docker-compose
systemctl enable docker
systemctl start docker

mkdir -p /opt/pihole
cat <<'EOF' > /opt/pihole/docker-compose.yml
version: "3"
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    ports:
      - "9080:80/tcp"
      - "8053:53/tcp"
      - "8053:53/udp"
    environment:
      TZ: "Asia/Ho_Chi_Minh"
      WEBPASSWORD: "admin"
    volumes:
      - /opt/pihole/etc-pihole:/etc/pihole
      - /opt/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
    restart: unless-stopped
EOF
cd /opt/pihole && docker compose up -d

# --- Cài Pi Network (Pi Node)
echo "[INFO] Cài Pi Network (Pi Node)..."
wget https://download.minepi.com/pi-node/setup.deb -O /tmp/pi-node.deb || true
apt install -y /tmp/pi-node.deb || echo "[WARN] Không tìm thấy gói chính thức Pi Node, vui lòng tải thủ công từ trang chủ."

# --- Dọn dẹp
apt autoremove -y
apt clean

echo "========================================================"
echo " ✅ Cài đặt hoàn tất!"
echo " Truy cập OMV:  http://$(hostname -I | awk '{print $1}'):8080"
echo " Truy cập Pi-hole: http://$(hostname -I | awk '{print $1}'):9080"
echo " Đăng nhập RDP (user root hoặc user bạn tạo) → XFCE desktop"
echo "========================================================"

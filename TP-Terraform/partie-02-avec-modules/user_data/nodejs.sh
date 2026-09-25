#!/bin/bash
# Serveur 2 (PRIVÉ) : SSM Agent + Node.js (sortie Internet via le NAT)
set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "=== Bootstrap démarré : $(date -Is) ==="

# --- AWS SSM Agent : installation + activation au démarrage ---
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

# --- Node.js ---
dnf install -y nodejs
dnf install -y npm || true
node --version

# --- Petite appli de test (prouve que Node.js "démarre") ---
mkdir -p /opt/node-hello
cat > /opt/node-hello/server.js <<'JS'
const http = require('http');
const os = require('os');
http.createServer((req, res) => {
  res.end(`Hello depuis Node.js ${process.version} sur ${os.hostname()}\n`);
}).listen(3000, '127.0.0.1');
JS

cat > /etc/systemd/system/node-hello.service <<'UNIT'
[Unit]
Description=Node.js hello app (TP tech_mind safta_ahmed)
After=network-online.target

[Service]
ExecStart=/usr/bin/node /opt/node-hello/server.js
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now node-hello

systemctl is-active amazon-ssm-agent node-hello
echo "BOOTSTRAP_OK $(date -Is)" > /var/log/bootstrap_status

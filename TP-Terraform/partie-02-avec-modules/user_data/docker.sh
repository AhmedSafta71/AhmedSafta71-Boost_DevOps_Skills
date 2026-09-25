#!/bin/bash
# Serveur 1 (PUBLIC) : SSM Agent + Docker
set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "=== Bootstrap démarré : $(date -Is) ==="

# --- AWS SSM Agent : installation + activation au démarrage ---
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

# --- Docker : installation + activation au démarrage ---
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

docker --version
systemctl is-active amazon-ssm-agent docker
echo "BOOTSTRAP_OK $(date -Is)" > /var/log/bootstrap_status

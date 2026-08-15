#!/bin/bash
#
# ufw_configuration.sh
# Applies a basic UFW firewall configuration.
# Run with: sudo ./ufw_configuration.sh
#

set -e

echo "[*] Installing UFW (if not already present)..."
sudo apt update
sudo apt install -y ufw

echo "[*] Enabling UFW..."
sudo ufw enable

echo "[*] Allowing SSH traffic (port 22)..."
sudo ufw allow ssh

echo "[*] Denying HTTP traffic (port 80)..."
sudo ufw deny http

echo "[*] Allowing HTTPS traffic (port 443)..."
sudo ufw allow https

echo "[*] Denying traffic from a specific IP (192.168.1.100)..."
sudo ufw deny from 192.168.1.100

echo "[*] Current firewall status:"
sudo ufw status verbose

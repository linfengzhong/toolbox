#!/usr/bin/env bash
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for Node Exporter installation
#-----------------------------------------------------------------------------
#fonts color 字体颜色配置
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Green="\033[32m"

RedBG="\033[41;37m"
GreenBG="\033[42;37m"

Font="\033[0m"
#-----------------------------------------------------------------------------
#notification information
Info="${Green}[Message信息]${Font}"
OK="${Green}[OK正常]${Font}"
Error="${Red}[ERROR错误]${Font}"
#-----------------------------------------------------------------------------
#打印OK
function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------
#打印错误
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}
#-----------------------------------------------------------------------------
#判定 成功 or 失败
judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 完成"
    sleep 1
  else
    print_error "$1 失败"
    exit 1
  fi
}
#-----------------------------------------------------------------------------
# Installing and running the Node Exporter
#-----------------------------------------------------------------------------
#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
#-----------------------------------------------------------------------------
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
#-----------------------------------------------------------------------------
print_ok "开始安装 node_exporter-1.1.2.linux-amd64"
sleep 2
print_ok "Step 1: Security-Enhanced Linux"
sleep 2
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
if ! command; then print_error "Step 1 failed"; exit 1; fi
print_ok "Step 1: Security-Enhanced Linux   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Download the relevant Node Exporter binary.
#-----------------------------------------------------------------------------
print_ok "Step 2: Download the relevant Node Exporter binary"
sleep 2
wget https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
if ! command; then print_error "Step 2 failed"; exit 1; fi
print_ok "Step 2: Download the relevant Node Exporter binary   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Unzip the tarball and move it to /usr/local/node_exporter.
#-----------------------------------------------------------------------------
print_ok "Step 3: Unzip the tarball and cd into the directory"
sleep 2
tar xvfz node_exporter-1.1.2.linux-amd64.tar.gz
mv node_exporter-1.1.2.linux-amd64 /usr/local/node_exporter
if ! command; then print_error "Step 3 failed"; exit 1; fi
print_ok "Step 3: Unzip the tarball and cd into the directory   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Create a node_exporter service.
#-----------------------------------------------------------------------------
print_ok "Step 4: Create a node_exporter service"
sleep 2
cat <<EOF >/usr/lib/systemd/system/node_exporter.service
[Unit]
Description=https://prometheus.io

[Service]
Restart=on-failure
ExecStart=/usr/local/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF
if ! command; then print_error "Step 4 failed"; exit 1; fi
print_ok "Step 4: Create a node_exporter service   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Enable and restart node_exporter service.
#-----------------------------------------------------------------------------
print_ok "Step 5: Enable and restart node_exporter service"
sleep 2
systemctl daemon-reload
print_ok "重新加载daemon-reload"
sleep 1
systemctl enable node_exporter
print_ok "Enable node_exporter服务"
sleep 1
systemctl restart node_exporter
print_ok "Restart node_exporter服务"
sleep 1
if ! command; then print_error "Step 5 failed"; exit 1; fi
print_ok "Step 5: Enable and restart node_exporter service   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Installation is done.
#-----------------------------------------------------------------------------
print_ok "安装成功：node_exporter-1.1.2.linux-amd64"
sleep 1
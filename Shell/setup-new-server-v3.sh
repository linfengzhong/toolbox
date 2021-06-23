#!/usr/bin/env bash
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-23 Fixed for Rocky 8.4
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
#打印Info
function print_info() {
  echo -e "${Info} ${Blue} $1 ${Font}"
}
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
    print_ok "$1 <--- 完成"
    sleep 1
  else
    print_error "$1 <--- 失败"
    exit 1
  fi
}
#-----------------------------------------------------------------------------
# Installing and running the Node Exporter
#-----------------------------------------------------------------------------
#===== RHEL 7/8 | CentOS 7/8 | Rocky Linux 8 =====
#-----------------------------------------------------------------------------
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
#-----------------------------------------------------------------------------
print_info "开始配置 Linux Rocky 8.4 服务器"
sleep 1
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
#judge "Step 1: Security-Enhanced Linux"
print_info "Step 1: Security-Enhanced Linux <--- 完成"
sleep 1
#-----------------------------------------------------------------------------
# Install Python3
# https://git-scm.com
#-----------------------------------------------------------------------------
# 安装必要程序
  yum -y install wget lsof tar unzip curl socat
  judge "安装 wget lsof tar unzip curl socat"
  sleep 3
#-----------------------------------------------------------------------------
# Install Docker CE
# https://docs.docker.com/engine/install/centos/
#-----------------------------------------------------------------------------
print_info "Step 2: Install Docker CE"
sleep 1
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
judge "Step 2: 1/3 Uninstall old versions of Docker CE"
sleep 1

sudo yum -y install yum-utils
sudo yum-config-manager \
      --add-repo \
      https://download.docker.com/linux/centos/docker-ce.repo

judge "Step 2: 2/3 Set up the repository for Docker"
sleep 1

sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
judge "Step 2: 3/3 Install Docker Engine"
sleep 1
judge "Step 2: Install Docker CE"
sleep 1
#-----------------------------------------------------------------------------
# Install Docker Compose
# https://docs.docker.com/compose/install/
#-----------------------------------------------------------------------------
print_info "Step 3: Install Docker Compose"
sleep 1
sudo rm -f /usr/local/bin/docker-compose
judge "Step 3: 1/3 Uninstallation"
sleep 1

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
          -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
judge "Step 3: 2/3 Install Compose on Linux systems"
sleep 1

sudo docker-compose --version
judge "Step 3: 3/3 Show docker-compose version"
sleep 3

judge "Step 3: Install Docker Compose"
#-----------------------------------------------------------------------------
# Install Git
# https://git-scm.com
#-----------------------------------------------------------------------------
print_info "Step 4: Install Git"
sudo yum -y install git
judge "Step 4: Install Git"
sleep 1
#-----------------------------------------------------------------------------
# Install webmin
# https://webmin.com
#-----------------------------------------------------------------------------
print_info "Step 5: Install webmin"
(echo "[Webmin]
name=Webmin Distribution Neutral
baseurl=http://download.webmin.com/download/yum
enabled=1
gpgcheck=1
gpgkey=http://www.webmin.com/jcameron-key.asc" >/etc/yum.repos.d/webmin.repo;)
sleep 1
sudo yum -y install webmin
sleep 1
judge "Step 5: Install webmin"
#-----------------------------------------------------------------------------
# Install acme.sh
#-----------------------------------------------------------------------------
print_info "Step 6: Install acme.sh"
sudo curl https://get.acme.sh | sh -s email=fred.zhong@outlook.com
print_info "----- 网站证书 ----"
sudo sh /root/.acme.sh/acme.sh  --issue  -d k8s-master.ml --standalone
print_info "----- 网站证书 ----"
sleep 1
judge "Step 6: Install acme.sh"

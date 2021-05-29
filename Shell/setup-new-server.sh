#!/usr/bin/env bash
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
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
#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
#-----------------------------------------------------------------------------
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
#-----------------------------------------------------------------------------
#DATE_TIME=`date "+%Y.%m.%d-%H:%M:%S"`
#sudo script -aq setup-new-server.${DATE_TIME}.log
# ./setup-new-server.sh >> setup-new-server.$`date "+%Y.%m.%d-%H:%M:%S"`.log 2>&1
print_info "开始配置 Linux CentOS 7 服务器"
sleep 1
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
#judge "Step 1: Security-Enhanced Linux"
print_info "Step 1: Security-Enhanced Linux <--- 完成"
sleep 1
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
# Install Git
# https://git-scm.com
#-----------------------------------------------------------------------------
sudo yum -y install git
judge "Step 3: Install Git"
sleep 1
#-----------------------------------------------------------------------------
# Install Python3
# https://git-scm.com
#-----------------------------------------------------------------------------
print_info "Step 4: Install Python3"
sudo yum -y install gcc libffi-devel python-devel python3-devel \
                    openssl-devel wget curl \
                    automake autoconf libtool make
judge "Step 4: 1/5 Install Prerequisites for Python3"
sleep 1

sudo wget https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tar.xz
judge "Step 4: 2/5 Download Python3.9.5.tar.xz"
sleep 1

sudo tar -xvf Python-3.9.5.tar.xz
judge "Step 4: 3/5 Unzip Python3.9.5.tar.xz"
cd Python-3.9.5
./configure --prefix=/usr/local/python3
judge "Step 4: 4/5 configure"
sleep 1

sudo make && make install
judge "Step 4: 5/5 Make & Make install"
sleep 3

sudo rm -f ~/Python-3.9.5.tar.xz
sudo rm -rf ~/Python-3.9.5
judge "Step 4: Install Python3"
#-----------------------------------------------------------------------------
# Install bpytop
# https://github.com/aristocratos/bpytop
#-----------------------------------------------------------------------------
#PyPi (will always have latest version)
#Install or update to latest version
print_info "Step 5: Install bpytop"
sudo pip3 install bpytop --upgrade
judge "Step 5: 1/2 Install bpytop"
sleep 1

echo 'alias bpytop=/usr/local/bin/bpytop'>>~/.bash_profile
source ~/.bash_profile 
judge "Step 5: 2/2 添加 bpytop 命令到.bash_profile"
sleep 1
judge "Step 5: Install bpytop"
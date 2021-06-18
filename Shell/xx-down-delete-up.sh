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
#-----------------------------------------------------------------------------#
# Installing and running the Node Exporter
#-----------------------------------------------------------------------------#
#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
#-----------------------------------------------------------------------------#
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
#-----------------------------------------------------------------------------#
print_info "Shutdown Docker Compose, Delete All-In-One folder & Docker Compose Up "
print_info "Step 1: 关闭 Docker Compose VM "
sleep 1

cd ~/all-in-one/
sleep 1
sudo docker-compose down
sleep 1
#sudo docker image rm -f all-in-one_*
#sleep 1
sudo docker images
judge "Step 1: 关闭 Docker Compose VM "
#-----------------------------------------------------------------------------#
print_info "Step 2: 删除 All-In-One 文件夹 "
cd ~
sleep 1
sudo rm -rf all-in-one/
ls -l
sleep 1
judge "Step 2: 删除 All-In-One 文件夹 "
#-----------------------------------------------------------------------------#
print_info "Step 3: 更新同步GitHub文件 -> All-In-One 文件夹 "
cd ~/git/toolbox/
sleep 1
git pull
sleep 1
sudo cp -rf ~/git/toolbox/Docker/docker-compose/all-in-one/ ~/
sleep 1
sudo chown -R root:root ~/all-in-one/
sleep 1
cd ~/all-in-one/
judge "Step 3: 更新同步GitHub文件 -> All-In-One 文件夹 "
sleep 1
#-----------------------------------------------------------------------------#
print_info "Step 4: 启动 Docker Compose "
sudo docker-compose build
sleep 1
sudo docker-compose up -d
sleep 1
sudo cp -f ~/git/toolbox/Shell/delete-all-in-one.sh ~/delete-all-in-one.sh
sudo cp -f ~/git/toolbox/Shell/down-docker-compose.sh ~/down-docker-compose.sh
sudo cp -f ~/git/toolbox/Shell/up-docker-compose.sh ~/up-docker-compose.sh
sudo cp -f ~/git/toolbox/Shell/setup-new-server.sh ~/setup-new-server.sh
sudo cp -f ~/git/toolbox/Shell/xx-down-delete-up.sh ~/xx-down-delete-up.sh
sleep 1
cd ~
sudo chmod +x ./*.sh
sudo chmod 777 -R ~/all-in-one
sleep 1
print_ok "Docker Container -> Running list "
sudo docker ps
sleep 1

judge "Step 4: 启动 Docker Compose "
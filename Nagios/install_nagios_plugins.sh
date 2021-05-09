#!/bin/sh
#
# Author: Linfeng Zhong (Fred)
# 2021-April-06 [Initial Version] - Shell Script for Nagios Plugins installing
#fonts color 字体颜色配置
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Green="\033[32m"

RedBG="\033[41;37m"
GreenBG="\033[42;37m"

Font="\033[0m"

#notification information
Info="${Green}[Message信息]${Font}"
OK="${Green}[OK正常]${Font}"
Error="${Red}[ERROR错误]${Font}"

#打印OK
function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

#打印错误
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}

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
# Nagios Plugins - Installing Nagios Plugins From Source
#-----------------------------------------------------------------------------
#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
#-----------------------------------------------------------------------------
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
print_ok "开始安装Nagios Plugins 2.3.3"
sleep 2
print_ok "Step1: Security-Enhanced Linux"
sleep 2
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
if ! command; then print_error "Step1 failed"; exit 1; fi
print_ok "Step1: Security-Enhanced Linux   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Prerequisites
# Perform these steps to install the pre-requisite packages.
print_ok "Step2: Prerequisites"
sleep 2
yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
yum install -y perl-Net-SNMP
if ! command; then print_error "Step2 failed"; exit 1; fi
print_ok "Step2: Prerequisites   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# Downloading the Source
#-----------------------------------------------------------------------------
#===== RHEL 5/6/7 | CentOS 5/6/7 | Oracle Linux 5/6/7 =========
#===== Debian =================================================
print_ok "Step3: 下载Nagios Plugins 2.2.3 到tmp文件夹"
sleep 2
cd /tmp
wget --no-check-certificate https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.3.3/nagios-plugins-2.3.3.tar.gz
tar xzf nagios-plugins-2.3.3.tar.gz
cd nagios-plugins-2.3.3
if ! command; then print_error "Step3 failed"; exit 1; fi
print_ok "Step3: 下载Nagios Plugins 2.2.3 到tmp文件夹   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# Nagios Plugins Installation
print_ok "Step4: 安装nagios plugins, 并重新启动nrpe服务"
sleep 2
./tools/setup
./configure
make
make install
systemctl restart nrpe
if ! command; then print_error "Step4 failed"; exit 1; fi
print_ok "Step4: 安装nagios plugins, 并重新启动nrpe服务   --> DONE"
sleep 2
#-----------------------------------------------------------------------------
# 这里是判断上条命令是否执行成功的语句块
if [ $? -eq 0 ]; then
   print_ok "Nagios Plugins 安装成功！"
   sleep 2
else
   print_error "Nagios Plugins 安装失败！"
   sleep 2
fi
# Plugin Installation Location
# The plugins will now be located in /usr/local/nagios/libexec/.
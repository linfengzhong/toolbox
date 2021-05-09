#!/usr/bin/env bash
# 安装Nagios NRPE
# -------------------------------------------------------------
###################################################################
#Security-Enhanced Linux
#This guide is based on SELinux being disabled or in permissive mode. Steps to do this are as follows.
echo "开始安装Nagios NRPE"
sleep 2
echo "Step1: SELINUX Disable"
sleep 2
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
if ! command; then echo "Step1 failed"; exit 1; fi
echo "Step1: SELINUX Disable  ---> DONE"
sleep 2
###################################################################
#Prerequisites
#Perform these steps to install the pre-requisite packages.
#===== RHEL 5/6/7 | CentOS 5/6/7 | Oracle Linux 5/6/7 =====
echo "Step2: Prerequisites"
sleep 2
yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
yum install -y perl-Net-SNMP
if ! command; then echo "Step2 failed"; exit 1; fi
echo "Step2: Prerequisites  ---> DONE"
sleep 2
###################################################################
#Download NRPE package
#下载NRPE包
echo "Step3: 下载nrpe-4.0.3到tmp文件夹"
sleep 2
cd /tmp
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.0.3/nrpe-4.0.3.tar.gz
tar xzf nrpe-4.0.3.tar.gz
cd nrpe-4.0.3
if ! command; then echo "Step2 failed"; exit 1; fi
echo "Step3: 下载nrpe-4.0.3到tmp文件夹  ---> DONE"
sleep 2
# -------------------------------------------------------------
#NPRE Installation
echo "Step4: 安装nrpe，设置用户和用户组、并初始化和启动nrpe服务"
sleep 2
./configure
make all
make install-groups-users
make install
make install-config
make install-init
systemctl enable nrpe 
systemctl start nrpe
if ! command; then echo "Step3 failed"; exit 1; fi
echo "Step4: 安装nrpe，设置用户和用户组、并初始化和启动nrpe服务  ---> DONE"
sleep 2
# -------------------------------------------------------------
#firewall enable port 5666
#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
echo "Step5: 设置防火墙开启端口5666"
sleep 2
firewall-cmd --zone=public --add-port=5666/tcp
firewall-cmd --zone=public --add-port=5666/tcp --permanent
if ! command; then echo "Step4 failed"; exit 1; fi
echo "Step5: 设置防火墙开启端口5666  ---> DONE"
sleep 2

# 这里是判断上条命令是否执行成功的语句块
if [ $? -eq 0 ]; then
   echo "nrpe 安装成功！"
   sleep 1
else
   echo "nrpe 安装失败！"
   sleep 1
fi

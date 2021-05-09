#!/bin/sh
#
# Author: Linfeng Zhong (Fred)
# 2021-April-06 [Initial Version] - Shell Script for Nagios Core installing
# Nagios Core - Installing Nagios Core From Source
#
# wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/Nagios/main/Host/install_nagios.sh" && chmod 700 /root/install_nagios.sh && /root/install_nagios.sh
# https://raw.githubusercontent.com/linfengzhong/Nagios/main/Host/install_nagios.sh
#
#-----------------------------------------------------------------------------
#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
#-----------------------------------------------------------------------------
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
echo "开始安装Nagios Core"
echo "Step1: Security-Enhanced Linux"
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
if ! command; then echo "Step1 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Prerequisites
# Perform these steps to install the pre-requisite packages.
# httpd -> Apache Web Server
echo "Step2: Prerequisites"
yum install -y gcc glibc glibc-common wget unzip httpd php gd gd-devel perl postfix
if ! command; then echo "Step2 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Downloading the Source
echo "Step3: Downloading the Source"
echo "nagios-4.4.5."
cd /tmp
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.5.tar.gz
tar xzf nagioscore.tar.gz
if ! command; then echo "Step3 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Compile
echo "Step4: Compile"
cd /tmp/nagioscore-nagios-4.4.5/
./configure
make all
if ! command; then echo "Step4 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Create User And Group
# This creates the nagios user and group. 
# The apache user is also added to the nagios group.
echo "Step5: Create User And Group"
make install-groups-users
usermod -a -G nagios apache
if ! command; then echo "Step5 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Install Binaries
# This step installs the binary files, CGIs, and HTML files.
echo "Step6: Install Binaries"
make install
if ! command; then echo "Step6 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Install Service / Daemon
# This installs the service or daemon files and also configures them to start on boot. 
# The Apache httpd service is also configured at this point.
echo "Step7: Install Service / Daemon"
make install-daemoninit
systemctl enable httpd.service
if ! command; then echo "Step7 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Install Command Mode
# This installs and configures the external command file.
echo "Step8: Install Command Mode"
make install-commandmode
if ! command; then echo "Step8 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Install Configuration Files
# This installs the *SAMPLE* configuration files. 
# These are required as Nagios needs some configuration files to allow it to start.
echo "Step9: Install Configuration Files"
make install-config
if ! command; then echo "Step9 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Install Apache Config Files
# This installs the Apache web server configuration files. 
# Also configure Apache settings if required.
echo "Step10: Install Apache Config Files"
make install-webconf
if ! command; then echo "Step10 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Configure Firewall
# You need to allow port 80 inbound traffic on the local firewall 
# so you can reach the Nagios Core web interface.
echo "Step11: Configure Firewall"
firewall-cmd --zone=public --add-port=8080/tcp
firewall-cmd --zone=public --add-port=8080/tcp --permanent
if ! command; then echo "Step11 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Create nagiosadmin User Account
# You'll need to create an Apache user account to be able to log into Nagios.
# The following command will create a user account called nagiosadmin and 
# you will be prompted to provide a password for the account.
echo "Step12: Create nagiosadmin User Account"
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
if ! command; then echo "Step12 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Start Apache Web Server
echo "Step13: Start Apache Web Server"
systemctl start httpd.service
if ! command; then echo "Step13 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# Start Service / Daemon
# This command starts Nagios Core.
echo "Step14: Start Service / Daemon for Nagios Core"
systemctl start nagios.service
if ! command; then echo "Step14 failed"; exit 1; fi
#-----------------------------------------------------------------------------
# 
# Test Nagios
# Nagios is now running, to confirm this you need to log into the Nagios Web Interface.
# Point your web browser to the ip address or FQDN of your Nagios Core server, 
# for example:
# http://10.25.5.143/nagios
# http://core-013.domain.local/nagios
#-----------------------------------------------------------------------------
# 

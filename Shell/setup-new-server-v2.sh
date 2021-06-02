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
# 检查系统
function checkSystem() {
	if [[ -n $(find /etc -name "redhat-release") ]] || grep </proc/version -q -i "centos"; then
		centosVersion=$(rpm -q centos-release | awk -F "[-]" '{print $3}' | awk -F "[.]" '{print $1}')

		if [[ -z "${centosVersion}" ]] && grep </etc/centos-release "release 8"; then
			centosVersion=8
		fi
		release="centos"
		installType='yum -y install'
		# removeType='yum -y remove'
		upgrade="yum update -y --skip-broken"

	elif grep </etc/issue -q -i "debian" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "debian" && [[ -f "/proc/version" ]]; then
		if grep </etc/issue -i "8"; then
			debianVersion=8
		fi
		release="debian"
		installType='apt -y install'
		upgrade="apt update -y"
		# removeType='apt -y autoremove'

	elif grep </etc/issue -q -i "ubuntu" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "ubuntu" && [[ -f "/proc/version" ]]; then
		release="ubuntu"
		installType='apt-get -y install'
		upgrade="apt-get update -y"
		# removeType='apt-get --purge remove'
	fi

	if [[ -z ${release} ]]; then
		echo "本脚本不支持此系统，请将下方日志反馈给开发者"
		cat /etc/issue
		cat /proc/version
		exit 0
	fi
}

# 初始化全局变量
initVar() {
	installType='yum -y install'
	removeType='yum -y remove'
	upgrade="yum -y update"
	echoType='echo -e'

	# 域名
	domain=

	# CDN节点的address
	add=

	# 安装总进度
	totalProgress=1

	# 1.xray-core安装
	# 2.v2ray-core 安装
	# 3.v2ray-core[xtls] 安装
	coreInstallType=

	# 核心安装path
	# coreInstallPath=

	# v2ctl Path
	ctlPath=
	# 1.全部安装
	# 2.个性化安装
	# v2rayAgentInstallType=

	# 当前的个性化安装方式 01234
	currentInstallProtocolType=

	# 选择的个性化安装方式
	selectCustomInstallType=

	# v2ray-core、xray-core配置文件的路径
	configPath=

	# 配置文件的path
	currentPath=

	# 配置文件的host
	currentHost=

	# 安装时选择的core类型
	selectCoreType=

	# 默认core版本
	v2rayCoreVersion=

	# 随机路径
	customPath=

	# centos version
	centosVersion=

	# UUID
	currentUUID=

	# pingIPv6 pingIPv4
	# pingIPv4=
	pingIPv6=

	# 集成更新证书逻辑不再使用单独的脚本--RenewTLS
	renewTLS=$1
}

# 检测安装方式
readInstallType() {
	coreInstallType=
	configPath=

	# 1.检测安装目录
	if [[ -d "/etc/v2ray-agent" ]]; then
		# 检测安装方式 v2ray-core
		if [[ -d "/etc/v2ray-agent/v2ray" && -f "/etc/v2ray-agent/v2ray/v2ray" && -f "/etc/v2ray-agent/v2ray/v2ctl" ]]; then
			if [[ -d "/etc/v2ray-agent/v2ray/conf" && -f "/etc/v2ray-agent/v2ray/conf/02_VLESS_TCP_inbounds.json" ]]; then
				configPath=/etc/v2ray-agent/v2ray/conf/

				if ! grep </etc/v2ray-agent/v2ray/conf/02_VLESS_TCP_inbounds.json -q xtls; then
					# 不带XTLS的v2ray-core
					coreInstallType=2
					# coreInstallPath=/etc/v2ray-agent/v2ray/v2ray
					ctlPath=/etc/v2ray-agent/v2ray/v2ctl
				elif grep </etc/v2ray-agent/v2ray/conf/02_VLESS_TCP_inbounds.json -q xtls; then
					# 带XTLS的v2ray-core
					# coreInstallPath=/etc/v2ray-agent/v2ray/v2ray
					ctlPath=/etc/v2ray-agent/v2ray/v2ctl
					coreInstallType=3
				fi
			fi
		fi

		if [[ -d "/etc/v2ray-agent/xray" && -f "/etc/v2ray-agent/xray/xray" ]]; then
			# 这里检测xray-core
			if [[ -d "/etc/v2ray-agent/xray/conf" && -f "/etc/v2ray-agent/xray/conf/02_VLESS_TCP_inbounds.json" ]]; then
				# xray-core
				configPath=/etc/v2ray-agent/xray/conf/
				# coreInstallPath=/etc/v2ray-agent/xray/xray
				ctlPath=/etc/v2ray-agent/xray/xray
				coreInstallType=1
			fi
		fi
	fi
}

function install_bash_5.1 {

	sudo yum -y install gcc

	wget https://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz

	tar -xvf bash-5.1.tar.gz

	cd bash-5.1

	./configure

	make & make install

}

function install_java_jdk {
	yum install java-1.8.0-openjdk.x86_64

}

function install_normal_sf {
	# socat是一个多功能的网络工具，名字来由是” Socket CAT”，可以看作是netcat的N倍加强版
	# nmap是一个网络连接端扫描软件，用来扫描网上电脑开放的网络连接端。
	# sysstat 
	sudo yum -y install socat openssl wget curl sysstat nmap lsof
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
# Install Docker Compose
# https://docs.docker.com/compose/install/
#-----------------------------------------------------------------------------
print_info "Step 3: Install Docker Compose"
sleep 1
sudo rm /usr/local/bin/docker-compose
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
sudo yum -y install git
judge "Step 4: Install Git"
sleep 1
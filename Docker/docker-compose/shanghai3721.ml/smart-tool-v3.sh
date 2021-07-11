#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-25 [Add new functions] - Stop/Start docker-compose
# 2021-July-09 [v3] - Remove non used functions
#-----------------------------------------------------------------------------#
#================== RHEL 7/8 | CentOS 7/8 | Rocky Linux 8 ====================#
#-----------------------------------------------------------------------------#
# 初始化全局变量
export LANG=en_US.UTF-8
function initVar() {
	# 网站 域名 配置文件的host
	# WEBSITE="k8s-master.ml"
	# domain="k8s-master.tk"
	currentHost="shanghai3721.ml"
	# UUID
	currentUUID="d8206743-b292-43d1-8200-5606238a5abb"

	#定义变量
	# WORKDIR="/root/git/toolbox/Docker/docker-compose/${currentHost}/"
	WORKDIR="/etc/fuckGFW/docker/${currentHost}/"
	LOGDIR="/root/git/logserver/${currentHost}/"
	GITHUB_REPO_TOOLBOX="/root/git/toolbox/"
	GITHUB_REPO_LOGSERVER="/root/git/logserver/"
	EMAIL="fred.zhong@outlook.com"
	#fonts color 字体颜色配置
	Red="\033[31m"
	Yellow="\033[33m"
	Blue="\033[36m"
	Green="\033[32m"
	RedBG="\033[41;37m"
	GreenBG="\033[42;37m"
	Magenta="\033[31m"
	Font="\033[0m"
	# Notification information 通知信息
	# Info="${Green}[Message信息]${Font}"
	Start="${Green}[Start开始]${Font}"
	Info="${Green}[Info信息]${Font}"
	OK="${Green}[OK正常]${Font}"
	Error="${Red}[ERROR错误]${Font}"
	DONE="${Magenta}[Done完成]${Font}"
	
	installType='yum -y install'
	removeType='yum -y remove'
	upgrade="yum -y update"
	echoType='echo -e'

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
	# 安装时选择的core类型
	selectCoreType=
	# 默认core版本
	v2rayCoreVersion=
	# 随机路径
	customPath=
	# centos version
	centosVersion=
	# pingIPv6 pingIPv4
	# pingIPv4=
	pingIPv6=
	# 集成更新证书逻辑不再使用单独的脚本--RenewTLS
	renewTLS=$1
}
#-----------------------------------------------------------------------------#
#打印Start
function print_start() {
	echo -e "${Start} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印Info
function print_info() {
	echo -e "${Info} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印OK
function print_ok() {
	echo -e "${OK} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印Done
function print_done() {
	echo -e "${DONE} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印Error
function print_error() {
	echo -e "${ERROR} ${RedBG} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#判定 成功 or 失败
function judge() {
	if [[ 0 -eq $? ]]; then
		print_done "$1" 
		#echoContent magenta "[Done完成]"
	else
		print_error "$1 <--- 失败"
		exit 1
	fi
}
#-----------------------------------------------------------------------------#
# 输出带颜色内容 字体颜色配置
function echoContent() {
	case $1 in
		# 红色
	"red")
		# shellcheck disable=SC2154
		${echoType} "\033[31m${printN}$2 \033[0m"
		;;
		# 天蓝色
	"skyBlue")
		${echoType} "\033[1;36m${printN}$2 \033[0m"
		;;
		# 绿色
	"green")
		${echoType} "\033[32m${printN}$2 \033[0m"
		;;
		# 白色
	"white")
		${echoType} "\033[37m${printN}$2 \033[0m"
		;;
		# 洋红
	"magenta")
		${echoType} "\033[31m${printN}$2 \033[0m"
		;;
		# 黄色
	"yellow")
		${echoType} "\033[33m${printN}$2 \033[0m"
		;;
	esac
}
#-----------------------------------------------------------------------------#
# Install Prerequisite
# 安装必要程序
function install_prerequisite () {
	print_start "安装 wget lsof tar unzip curl socat nmap "
	yum -y install wget lsof tar unzip curl socat nmap
	judge "安装 wget lsof tar unzip curl socat nmap "
}
#-----------------------------------------------------------------------------#
# Install acme.sh
function install_acme () {
	print_start "Install acme.sh "
	sudo curl https://get.acme.sh | sh -s email=$EMAIL
	judge "安装 acme.sh "
}
#-----------------------------------------------------------------------------#
# Install bpytop
# https://github.com/aristocratos/bpytop
# PyPi (will always have latest version)
# Install or update to latest version
function install_bpytop () {
	print_start "Install Prerequisites for Python3 "
	sudo yum -y install gcc libffi-devel python3-devel \
                    openssl-devel \
                    automake autoconf libtool make
	judge "Install Prerequisites for Python3 "

	print_start "Install bpytop "
	sudo pip3 install bpytop --upgrade
	judge "1/2 Install bpytop "

	echo 'alias bpytop=/usr/local/bin/bpytop'>>~/.bash_profile
	source ~/.bash_profile 
	judge "2/2 添加 bpytop 命令到.bash_profile"

	judge "Install bpytop"
}
#-----------------------------------------------------------------------------#
# Install webmin
# https://webmin.com
# https://doxfer.webmin.com/Webmin/Installation
function install_webmin () {
	print_start "Install webmin "
	(echo "[Webmin]
name=Webmin Distribution Neutral
baseurl=http://download.webmin.com/download/yum
enabled=1
gpgcheck=1
gpgkey=http://www.webmin.com/jcameron-key.asc" >/etc/yum.repos.d/webmin.repo;)
	sleep 1
	sudo yum -y install webmin
	judge "Install webmin "
}
#-----------------------------------------------------------------------------#
# Install Docker CE
# https://docs.docker.com/engine/install/centos/
function install_docker () {
	print_start "Install Docker CE "
	sudo yum -y remove docker \
					docker-client \
					docker-client-latest \
					docker-common \
					docker-latest \
					docker-latest-logrotate \
					docker-logrotate \
					docker-engine
	judge "1/3 Uninstall old versions of Docker CE "
	sudo yum -y install yum-utils
	sudo yum-config-manager \
			--add-repo \
			https://download.docker.com/linux/centos/docker-ce.repo
	judge "2/3 Set up the repository for Docker "
	sudo yum -y install docker-ce docker-ce-cli containerd.io
	sudo systemctl start docker
	sudo systemctl enable docker
	judge "3/3 Install Docker Engine "
	judge "Install Docker CE "
}
#-----------------------------------------------------------------------------#
# Install Docker Compose
# https://docs.docker.com/compose/install/#install-compose
function install_docker_compose () {
	print_start "Install docker compose "
	sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	docker-compose --version
	judge "Install docker compose "
}
#-----------------------------------------------------------------------------#
# Install Git
# https://git-scm.com
function install_git () {
	print_start "Install Git "
	sudo yum -y install git
	judge "Install Git "
}
#-----------------------------------------------------------------------------#
# 安装 v2ray-agent
function InstallV2rayAgent {
	# https://github.com/mack-a/v2ray-agent
	print_start "安装 v2ray-agent "
	wget -c -q --show-progress -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" 
	chmod 700 /root/install.sh
	judge "安装 v2ray-agent "
	print_info "运行 v2ray-agent "
	sleep 2
	cd $HOME
	./install.sh
}
#-----------------------------------------------------------------------------#
# 安装 BBR
function install_bbr() {
	echoContent red "\n=============================================================="
	echoContent green "BBR、DD脚本用的[ylx2016]的成熟作品，请熟知"
	echoContent green "地址 https://github.com/ylx2016/Linux-NetSpeed"
	echoContent yellow "1.安装脚本【推荐原版BBR+FQ】"
	echoContent yellow "2.回退主目录"
	echoContent red "=============================================================="
	read -r -p "请选择：" installBBRStatus
	if [[ "${installBBRStatus}" == "1" ]]; then
		wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
	else
		menu
	fi
}
#-----------------------------------------------------------------------------#
# 清理屏幕
function cleanScreen() {
	clear
}
#-----------------------------------------------------------------------------#
# 调用bpytop
function execBpytop() {
	/usr/local/bin/bpytop
}
#-----------------------------------------------------------------------------#
# Shutdown Docker Compose, Delete All-In-One folder & Docker Compose Up
# 关闭docker-compose
function shutdown_docker_compose () {
	print_start "Shutdown Docker Compose "
	print_info "关闭 Docker Compose VM "
	cd $WORKDIR
	sudo docker-compose down
	judge "关闭 Docker Compose VM "
}
#-----------------------------------------------------------------------------#
# 启动docker-compose
function start_docker_compose () {
	print_start "启动 Docker Compose "
	cd $WORKDIR
	sudo docker-compose build
	sudo docker-compose up -d
	judge "启动 Docker Compose "
}
#-----------------------------------------------------------------------------#
# 查看Docker Images
function show_docker_images () {
	print_info "查看Docker Images "
	sudo docker images
}
#-----------------------------------------------------------------------------#
# 列出所有运行的docker container
function show_docker_container () {
	print_info "列出所有运行的docker container "
	sudo docker container ps
}
#-----------------------------------------------------------------------------#
# Git global configuration
# https://git-scm.com
#-----------------------------------------------------------------------------#
function git_init () {
	print_start "初始化 Git "
	if [[ -d "$HOME/git" ]];then
		echoContent yellow "Git文件夹已存在，无需初始化Git！"
	else
		git config --global user.name "root" 
		git config --global user.email "root@${currentHost}"
		git config --global pull.rebase false
		cd ~
		mkdir -p git
		cd git
		ssh-keygen -t rsa -C fred.zhong@outlook.com
		print_info "请复制下面的Public key到GitHub "
		print_info "======== Public key========= "
		cat ~/.ssh/id_rsa.pub
		print_info "======== Public key End========= "
		judge "初始化 Git "
	fi
}
#-----------------------------------------------------------------------------#
# Git clone toolbox.git
function git_clone_toolbox () {
	print_start "Git clone ToolBox "
	if [[ -d "$HOME/git/toolbox" ]];then
		echoContent yellow "toolbox文件夹已存在，无需重新clone！"
	else
		cd  $HOME/git/
		git clone git@github.com:linfengzhong/toolbox.git
		judge "Git clone ToolBox "
	fi
}
#-----------------------------------------------------------------------------#
# 同步下载Git文件夹
function github_pull_toolbox () {
	echoContent yellow " ---> ToolBox"
	print_start "下载 -> Local toolbox Repo "
	cd $GITHUB_REPO_TOOLBOX
	sudo git pull
	cp -pf $GITHUB_REPO_TOOLBOX/Docker/$currentHost/smart-tool-v3.sh $HOME
	aliasInstall
	judge "下载 -> Local toolbox Repo "
}
#-----------------------------------------------------------------------------#
# 同步上传Git文件夹
function github_push_toolbox () {
	echoContent yellow " ---> ToolBox"
	print_start "上传 -> GitHub "
	cd $GITHUB_REPO_TOOLBOX
	sudo git add .
	sudo git commit -m "$date sync_all_config_log_data"
	sudo git push
	judge "上传 -> GitHub "
}
#-----------------------------------------------------------------------------#
# Git clone logserver.git
function git_clone_logserver () {
	print_start "Git clone logserver "
	if [[ -d "$HOME/git/logserver" ]];then
		echoContent yellow "logserver文件夹已存在，无需重新clone！"
	else
		cd  $HOME/git/
		git clone git@github.com:linfengzhong/logserver.git
		judge "Git clone logserver "
	fi
}
#-----------------------------------------------------------------------------#
# 同步下载Git文件夹
function github_pull_logserver () {
	echoContent yellow " ---> logserver"
	print_start "下载 -> Local logserver Repo "
	cd $GITHUB_REPO_LOGSERVER
	sudo git pull
	judge "下载 -> Local logserver Repo "
}
#-----------------------------------------------------------------------------#
# 同步上传Git文件夹
function github_push_logserver () {
	echoContent yellow " ---> logserver"
	print_start "上传 -> GitHub "
	cd $GITHUB_REPO_LOGSERVER
	sudo git add .
	sudo git commit -m "$date sync_all_config_log_data"
	sudo git push
	judge "上传 -> GitHub "
}
#-----------------------------------------------------------------------------#
# 检查系统
function checkSystem() {
	if [[ -n $(find /etc -name "rocky-release") ]] || grep </proc/version -q -i "rockylinux"; then
		mkdir -p /etc/yum.repos.d

		if [[ -f "/etc/rocky-release" ]];then
			centosVersion=$(rpm -q rocky-release | awk -F "[-]" '{print $3}' | awk -F "[.]" '{print $1}')

			if [[ -z "${centosVersion}" ]] && grep </etc/rocky-release "version 8"; then
				centosVersion=8
			fi
		fi
		release="rocky"
		installType='yum -y install'
		removeType='yum -y remove'
		upgrade="yum update -y --skip-broken"
		echoContent white "Rocky Linux release 8.4 (Green Obsidian)"

	elif [[ -n $(find /etc -name "redhat-release") ]] || grep </proc/version -q -i "centos"; then
		mkdir -p /etc/yum.repos.d

		if [[ -f "/etc/centos-release" ]];then
			centosVersion=$(rpm -q centos-release | awk -F "[-]" '{print $3}' | awk -F "[.]" '{print $1}')

			if [[ -z "${centosVersion}" ]] && grep </etc/centos-release "release 8"; then
				centosVersion=8
			fi
		fi
		release="centos"
		installType='yum -y install'
		removeType='yum -y remove'
		upgrade="yum update -y --skip-broken"
		echoContent white "CentOS 8.4"

	elif grep </etc/issue -q -i "debian" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "debian" && [[ -f "/proc/version" ]]; then
		if grep </etc/issue -i "8"; then
			debianVersion=8
		fi
		release="debian"
		installType='apt -y install'
		upgrade="apt update -y"
		removeType='apt -y autoremove'

	elif grep </etc/issue -q -i "ubuntu" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "ubuntu" && [[ -f "/proc/version" ]]; then
		release="ubuntu"
		installType='apt-get -y install'
		upgrade="apt-get update -y"
		removeType='apt-get --purge remove'
	fi

	if [[ -z ${release} ]]; then
		echo "本脚本不支持此系统，请将下方日志反馈给开发者"
		cat /etc/issue
		cat /proc/version
		exit 0
	fi
}
#-----------------------------------------------------------------------------#
# Generate CA
function generate_ca () {
	print_info "默认域名: $currentHost"	
	local tempDomainName
	show_ip
	read -r -p "如与默认域名不一致，请输入与本服务器绑定IP的新域名: " tempDomainName
	if [ $tempDomainName ]; then
		print_info "----- 新域名证书 ----"
		sh /root/.acme.sh/acme.sh  --issue  -d $tempDomainName --standalone --force
		print_info "----- 新域名证书 ----"
		print_info "----- 保存新域名证书到 /etc/fuckGFW/tls ----"
		cp -pf $HOME/.acme.sh/$tempDomainName/*.cer /etc/fuckGFW/tls/
		cp -pf $HOME/.acme.sh/$tempDomainName/*.key /etc/fuckGFW/tls/
	else
		print_error "未输入域名，使用默认域名: $currentHost"
		print_info "----- 默认域名证书 ----"
		sh /root/.acme.sh/acme.sh  --issue  -d $currentHost --standalone --force
		print_info "----- 默认域名证书 ----"
		print_info "----- 保存默认域名证书到 /etc/fuckGFW/tls ----"
		cp -pf $HOME/.acme.sh/$currentHost/*.cer /etc/fuckGFW/tls/
		cp -pf $HOME/.acme.sh/$currentHost/*.key /etc/fuckGFW/tls/
	fi
	judge "生成网站证书 "
}
#-----------------------------------------------------------------------------#
# 更新证书
function renewalTLS() {
	echoContent skyBlue "更新证书 "

	if [[ -d "$HOME/.acme.sh/${currentHost}" ]] && [[ -f "$HOME/.acme.sh/${currentHost}/${currentHost}.key" ]] && [[ -f "$HOME/.acme.sh/${currentHost}/${currentHost}.cer" ]]; then
		modifyTime=$(stat $HOME/.acme.sh/${currentHost}/${currentHost}.cer | sed -n '7,6p' | awk '{print $2" "$3" "$4" "$5}')

		modifyTime=$(date +%s -d "${modifyTime}")
		currentTime=$(date +%s)
		stampDiff=$(expr ${currentTime} - ${modifyTime})
		days=$(expr ${stampDiff} / 86400)
		remainingDays=$(expr 90 - ${days})
		tlsStatus=${remainingDays}
		if [[ ${remainingDays} -le 0 ]]; then
			tlsStatus="已过期"
		fi

		print_info " ---> 证书检查日期:$(date "+%F %H:%M:%S")"
		print_info " ---> 证书生成日期:$(date -d @"${modifyTime}" +"%F %H:%M:%S")"
		print_info " ---> 证书生成天数:${days}"
		print_info " ---> 证书剩余天数:"${tlsStatus}
		print_info " ---> 证书过期前最后一天自动更新，如更新失败请手动更新"

		if [[ ${remainingDays} -le 1 ]]; then
			echoContent yellow " ---> 重新生成证书"
			sh /root/.acme.sh/acme.sh  --issue  -d $currentHost --standalone --force

		else
			echoContent green " ---> 证书有效"
		fi
	else
		echoContent red " ---> 未安装"
	fi
}
#-----------------------------------------------------------------------------#
# 查看TLS证书的状态
function checkTLStatus() {
	print_info "当前域名: ${currentHost}"
	if [[ -n "$1" ]]; then
		if [[ -d "$HOME/.acme.sh/$1" ]] && [[ -f "$HOME/.acme.sh/$1/$1.key" ]] && [[ -f "$HOME/.acme.sh/$1/$1.cer" ]]; then
			modifyTime=$(stat $HOME/.acme.sh/$1/$1.key | sed -n '7,6p' | awk '{print $2" "$3" "$4" "$5}')

			modifyTime=$(date +%s -d "${modifyTime}")
			currentTime=$(date +%s)
			stampDiff=$(expr ${currentTime} - ${modifyTime})
			days=$(expr ${stampDiff} / 86400)
			remainingDays=$(expr 90 - ${days})
			tlsStatus=${remainingDays}
			if [[ ${remainingDays} -le 0 ]]; then
				tlsStatus="已过期"
			fi
			echoContent skyBlue " ---> 证书生成日期:$(date -d "@${modifyTime}" +"%F %H:%M:%S")"
			echoContent skyBlue " ---> 证书生成天数:${days}"
			echoContent skyBlue " ---> 证书剩余天数:${tlsStatus}"
		fi
	fi
}
#-----------------------------------------------------------------------------#
# 定时任务更新tls证书
function installCronTLS() {
	echoContent skyBlue "添加定时维护证书"
	crontab -l >/etc/fuckGFW/backup_crontab.cron
	sed '/fuckGFW/d;/acme.sh/d' /etc/fuckGFW/backup_crontab.cron >/etc/fuckGFW/backup_crontab.cron
	echo "30 1 * * * /bin/bash /etc/fuckGFW/install.sh RenewTLS" >>/etc/fuckGFW/backup_crontab.cron
	crontab /etc/fuckGFW/backup_crontab.cron
	echoContent green "\n ---> 添加定时维护证书成功"
}

#-----------------------------------------------------------------------------#
# 调用
# echoContent green " ---> 检测到证书"
#		checkTLStatus "${tlsDomain}"
#-----------------------------------------------------------------------------#
# 脚本快捷方式
function aliasInstall() {
	if [[ -f "$HOME/smart-tool-v3.sh" ]] && [[ -d "/etc/smart-tool" ]] && grep <$HOME/smart-tool-v3.sh -q "Author: Linfeng Zhong (Fred)"; then
		mv "$HOME/smart-tool-v3.sh" /etc/smart-tool/smart-tool-v3.sh
		if [[ -d "/usr/bin/" ]] && [[ ! -f "/usr/bin/st" ]]; then
			ln -s /etc/smart-tool/smart-tool-v3.sh /usr/bin/st
			chmod 700 /usr/bin/st
			rm -rf "$HOME/smart-tool-v3.sh"
		elif [[ -d "/usr/sbin" ]] && [[ ! -f "/usr/sbin/st" ]]; then
			ln -s /etc/smart-tool/smart-tool-v3.sh /usr/sbin/st
			chmod 700 /usr/sbin/st
			rm -rf "$HOME/smart-tool-v3.sh"
		fi
	fi
	echoContent green "快捷方式创建成功，可执行[st]重新打开脚本"
}
#-----------------------------------------------------------------------------#
# 更新脚本
function updateSmartTool() {
	rm -rf /etc/smart-tool/smart-tool-v3.sh
	echoContent skyBlue "开始下载： "
	if wget --help | grep -q show-progress; then
		wget -c -q --show-progress -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Docker/docker-compose/${currentHost}/smart-tool-v3.sh"
  	else
		wget -c -q -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Docker/docker-compose/${currentHost}/smart-tool-v3.sh"
	fi

	sudo chmod 700 /etc/smart-tool/smart-tool-v3.sh
	local newversion=$(cat /etc/smart-tool/smart-tool-v3.sh | grep 'SmartTool：v' | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')

	print_info "---> 更新完毕"
	print_info "---> 当前版本:${newversion}"
	print_info "---> 请手动执行[st]打开脚本\n"
#	echoContent yellow "如更新不成功，请手动执行下面命令"
#	echoContent skyBlue "wget -P /root -N --no-check-certificate\
#  "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v3.sh" &&\
#  chmod 700 /root/smart-tool-v3.sh && /root/smart-tool-v3.sh"
	echo
	exit 0
}
#-----------------------------------------------------------------------------#
# 初始化安装目录
function mkdirTools() {
	mkdir -p /etc/smart-tool

	mkdir -p /etc/fuckGFW/docker/${currentHost}
	mkdir -p /etc/fuckGFW/website/html
	mkdir -p /etc/fuckGFW/tls
#	mkdir -p /etc/fuckGFW/mtg
#	mkdir -p /etc/fuckGFW/subscribe
#	mkdir -p /etc/fuckGFW/subscribe_tmp
	mkdir -p /etc/fuckGFW/nginx/conf.d
	mkdir -p /etc/fuckGFW/v2ray/
	mkdir -p /etc/fuckGFW/xray/${currentHost}
	mkdir -p /etc/fuckGFW/trojan-go/
#	mkdir -p /etc/systemd/system/
#	mkdir -p /tmp/fuckGFW-tls/

}

#-----------------------------------------------------------------------------#
# Show IP
function show_ip () {
	local zIP=$(curl -s https://ipinfo.io/ip)
	print_info "服务器外部 IP: $zIP "
}
#-----------------------------------------------------------------------------#
# Generate UUID
function generate_uuid () {
	local zUUID=$(cat /proc/sys/kernel/random/uuid)
	print_info "随机生成 UUID: $zUUID "
}
#-----------------------------------------------------------------------------#
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
function turn_off_selinux () {
	print_start "配置 Linux Rocky 8.4 / CentOS 8 服务器"
	sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
	#judge "Step 1: Security-Enhanced Linux"
	print_info "Security-Enhanced Linux <--- 完成"
}
#-----------------------------------------------------------------------------#
# 查看、检查日志
# 安装TLS
# 操作Nginx
# 配置伪装博客
# 自定义/随机路径
# 安装xray
# Xray开机自启
# 自定义CDN IP
# 初始化Xray 配置文件
# 定时任务更新tls证书
# Nginx伪装博客
# 修改nginx重定向配置
# 验证整个服务是否可用
# 账号
# xray-core 安装
# 安装Trojan-go
# 更新Trojan-Go
# 操作Trojan-Go
# 清理旧残留
# 安装工具包
#-----------------------------------------------------------------------------#
# 定时任务检查证书
cronRenewTLS() {
	if [[ "${renewTLS}" == "RenewTLS" ]]; then
		renewalTLS
		exit 0
	fi
}
#-----------------------------------------------------------------------------#
# 生成 Nginx 配置文件
function generate_nginx_conf {
	# /etc/fuckGFW/nginx/conf
	print_start "生成 NGINX 配置文件 "
	print_info "/etc/fuckGFW/nginx/conf.d/${currentHost}.conf"

	cat <<EOF >/etc/fuckGFW/nginx/conf.d/${currentHost}.conf
server {
    listen 80;
    server_name ${currentHost};
    return 301 https://${currentHost};
}

server {
    listen 31300;
    server_name ${currentHost};
    root /usr/share/nginx/html;

    location / {
        add_header Strict-Transport-Security "max-age=63072000" always;
    }

    location /portainer/ {
        proxy_pass http://portainer:9000/;
    }
}
EOF
	cat /etc/fuckGFW/nginx/conf.d/${currentHost}.conf
	judge "生成 NGINX 配置文件 "

}

#-----------------------------------------------------------------------------#
# 生成 xray 配置文件
function generate_xray_conf {
	# https://xtls.github.io/config/
	# /etc/fuckGFW/xray
	# error 日志的级别, 指示 error 日志需要记录的信息. 默认值为 "warning"。
	#	"debug"：调试程序时用到的输出信息。同时包含所有 "info" 内容。
	#	"info"：运行时的状态信息等，不影响正常使用。同时包含所有 "warning" 内容。
	#	"warning"：发生了一些并不影响正常运行的问题时输出的信息，但有可能影响用户的体验。同时包含所有 "error" 内容。
	#	"error"：Xray 遇到了无法正常运行的问题，需要立即解决。
	#	"none"：不记录任何内容。

	print_start "生成 xray 配置文件 "
	print_info "/etc/fuckGFW/xray/config.json"

	cat <<EOF >/etc/fuckGFW/xray/config.json
{
  "log": {
    "access": "/etc/xray/access.log",
    "error": "/etc/xray/error.log",
    "loglevel": "debug"
  },

  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "tag": "VLESSTCP",
      "settings": {
        "clients": [
          {
            "id": "${currentUUID}",
            "add": "${currentHost}",
            "flow": "xtls-rprx-direct",
            "email": "${currentHost}_VLESS_XTLS/TLS-direct_TCP"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": "trojan-go:31296",
            "xver": 0
          },
          {
            "path": "/rrdaws",
            "dest": 31297,
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.2",
          "alpn": [
            "http/1.1",
            "h2"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/xray/${currentHost}/fullchain.cer",
              "keyFile": "/etc/xray/${currentHost}/${currentHost}.key",
              "ocspStapling": 3600,
              "usage": "encipherment"
            }
          ]
        }
      }
    },
    {
      "port": 31297,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "tag": "VLESSWS",
      "settings": {
        "clients": [
          {
            "id": "${currentUUID}",
            "email": "${currentHost}_vless_ws"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/rrdaws"
        }
      }
    }
  ],

  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "tag": "IPv4-out"
    }
  ],

  "dns": {
    "servers": [
      "localhost"
    ]
  }
}
EOF

	cat /etc/fuckGFW/xray/config.json
	judge "生成 xray 配置文件 "
	print_info "复制证书到xray配置文件夹 "
	cp -pf /etc/fuckGFW/tls/*.* /etc/fuckGFW/xray/${currentHost}/

}
#-----------------------------------------------------------------------------#
# 生成 trojan-go 配置文件
function generate_trojan_go_conf {
	# https://p4gefau1t.github.io/trojan-go/basic/full-config/
	# /etc/fuckGFW/trojan-go
	# log_level指定日志等级。等级越高，输出的信息越少。合法的值有
	#	0 输出Debug以上日志（所有日志）
	#	1 输出Info及以上日志
	#	2 输出Warning及以上日志
	#	3 输出Error及以上日志
	#	4 输出Fatal及以上日志
	#	5 完全不输出日志

	print_start "生成 trojan-go 配置文件 "
	print_info "/etc/fuckGFW/trojan-go/config.json"

	cat <<EOF >/etc/fuckGFW/trojan-go/config.json
{
    "run_type": "server",
    "local_addr": "trojan-go",
    "local_port": 31296,
    "remote_addr": "nginx",
    "remote_port": 31300,
    "disable_http_check":true,
    "log_level":0,
    "log_file":"/etc/trojan-go/trojan.log",
    "password": [
        "${currentUUID}"
    ],
    "dns":[
        "localhost"
    ],
    "transport_plugin":{
        "enabled":true,
        "type":"plaintext"
    },
    "websocket": {
        "enabled": true,
        "path": "/rrdatws",
        "host": "${currentHost}",
        "add": "${currentHost}"
    },
    "router": {
        "enabled": false
    }
}
EOF

	cat /etc/fuckGFW/trojan-go/config.json
	judge "生成 trojan-go 配置文件 "

}
#-----------------------------------------------------------------------------#
# 生成 v2ray 配置文件
function generate_v2ray_conf {
	# https://www.v2fly.org/config/overview.html
	# /etc/fuckGFW/v2ray
	# loglevel: "debug" | "info" | "warning" | "error" | "none"
	# 日志的级别。默认值为 "warning"。
	#	"debug"：详细的调试性信息。同时包含所有 "info" 内容。
	#	"info"：V2Ray 在运行时的状态，不影响正常使用。同时包含所有 "warning" 内容。
	#	"warning"：V2Ray 遇到了一些问题，通常是外部问题，不影响 V2Ray 的正常运行，但有可能影响用户的体验。同时包含所有 "error" 内容。
	#	"error"：V2Ray 遇到了无法正常运行的问题，需要立即解决。
	#	"none"：不记录任何内容。

	print_start "生成 v2ray 配置文件 "
	print_info "/etc/fuckGFW/v2ray/config.json"

	cat <<EOF >/etc/fuckGFW/v2ray/config.json
{
  "log": {
    "access": "/etc/v2ray/access.log",
    "error": "/etc/v2ray/error.log",
    "loglevel": "debug"
  },

  "inbounds":[
    {
      "port": 443,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "tag":"trojanTCP",
      "settings": {
        "clients": [
          {"password": "${currentUUID}",
           "email": "${currentHost}_trojan_tcp"}
          ],
        "fallbacks":[
          {"dest":"nginx:31300"}
          ]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "none",
          "tcpSettings": {
            "acceptProxyProtocol": true
          }
        }
    }
  ],
  "outbounds":[
    {
      "protocol":"freedom",
      "settings":{
        "domainStrategy":"UseIPv4"
      },
      "tag":"IPv4-out"
    },

    {
      "protocol":"freedom",
      "settings":{
        "domainStrategy":"UseIPv6"
      },
      "tag":"IPv6-out"
    },

    {
      "protocol":"blackhole",
      "tag":"blackhole-out"
    }
  ],
  "dns": {
    "servers": [
      "localhost"
    ]
  }
}
EOF

	cat /etc/fuckGFW/v2ray/config.json
	judge "生成 v2ray 配置文件 "

}
#-----------------------------------------------------------------------------#
# 生成 docker-compose.yml 配置文件
function generate_docker_compose_yml {

	print_start "生成 docker-compose.yml 配置文件 "
	print_info "/etc/fuckGFW/docker/${currentHost}/docker-compose.yml"

	cat <<EOF >/etc/fuckGFW/docker/${currentHost}/docker-compose.yml
version: '3.8'
services:
    #1. Nginx -> proxy server
    #--> Working
    # listen 80, 31300 --> Mock website https://${currentHost}
    # proxy pass
    # /portainer/ --> proxy_pass http://portainer:9000/;
    nginx:
        image: nginx:alpine
        container_name: nginx
        restart: always
        environment: 
            TZ: Asia/Shanghai
        ports:
            - 80:80
        volumes: 
            - /etc/fuckGFW/nginx/conf.d/:/etc/nginx/conf.d
            - /etc/fuckGFW/website/html:/usr/share/nginx/html
            # Store data on logserver
            - /root/git/logserver/${currentHost}/nginx/error.log:/var/log/nginx/error.log
            - /root/git/logserver/${currentHost}/nginx/access.log:/var/log/nginx/access.log
        networks: 
            - net
    #2. trojan go -> fuck GFW
    #--> Working
    trojan-go:
        image: p4gefau1t/trojan-go:latest
        container_name: trojan-go
        restart: always
        environment: 
            TZ: Asia/Shanghai
        expose:
            - 31296
        volumes:
            - /etc/fuckGFW/trojan-go/config.json:/etc/trojan-go/config.json
            # Store data on logserver
            - /root/git/logserver/${currentHost}/trojan-go/trojan.log:/etc/trojan-go/trojan.log           
        networks: 
            - net
        depends_on:
            - nginx
    #3. xray -> fuck GFW * Proxy Server
    # VLESS_XTLS/TLS-direct_TCP
    # VLESS_WS
    #--> Working
    xray:
        image: teddysun/xray:latest
        container_name: xray
        restart: always
        environment: 
            TZ: Asia/Shanghai
        ports: 
            - 443:443
        volumes: 
            - /etc/fuckGFW/xray/config.json:/etc/xray/config.json
            # CA & Key
            - /etc/fuckGFW/xray/${currentHost}:/etc/xray/${currentHost}
            # Store date on logserver
            - /root/git/logserver/${currentHost}/xray/error.log:/etc/xray/error.log
            - /root/git/logserver/${currentHost}/xray/access.log:/etc/xray/access.log
        networks: 
            - net
        depends_on:
            - nginx
    #4. v2ray -> fuck GFW * Proxy Server
    #--> Working
    v2ray:
        image: v2fly/v2fly-core:latest
        container_name: v2ray
        restart: always
        environment: 
            TZ: Asia/Shanghai
        expose:
            - 443
        volumes:
            - /etc/fuckGFW/v2ray/config.json:/etc/v2ray/config.json
            # Store data on logserver
            - /root/git/logserver/${currentHost}/v2ray/error.log:/etc/v2ray/error.log
            - /root/git/logserver/${currentHost}/v2ray/access.log:/etc/v2ray/access.log   
        networks: 
            - net
        depends_on:
            - nginx
    #5. Portainer -> Docker UI
    #--> Working
    portainer:
        image: portainer/portainer-ce:alpine
        container_name: portainer
        restart: always
        environment: 
            TZ: Asia/Shanghai
        expose: 
            - 8000
            - 9000
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            # 持久化配置文件
            # Store data on logserver
            - /root/git/logserver/${currentHost}/portainer/data:/data
        networks: 
            - net
networks: 
    net:
        driver: bridge
EOF

	cat /etc/fuckGFW/docker/${currentHost}/docker-compose.yml
	judge "生成 trojan-go 配置文件 "

}
#-----------------------------------------------------------------------------#
# Website
function generate_fake_website {
#	/etc/fuckGFW/website
#	https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html1.zip
#	https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html2.zip
#	https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html3.zip
#	https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html4.zip
#	https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html5.zip
#	https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html5.zip
	print_start "添加随机伪装站点 "
	if [[ -d "/etc/fuckGFW/website/html" && -f "/etc/fuckGFW/website/html/check" ]]; then
		echo
		read -r -p "检测到安装伪装站点，是否需要重新安装[y/n]：" nginxBlogInstallStatus
		if [[ "${nginxBlogInstallStatus}" == "y" ]]; then
			rm -rf /etc/fuckGFW/website/html
			randomNum=$((RANDOM%6+1))
			wget -q -P /etc/fuckGFW/website https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html${randomNum}.zip >/dev/null
			unzip -o /etc/fuckGFW/website/html${randomNum}.zip -d /etc/fuckGFW/website/html >/dev/null
			rm -f /etc/fuckGFW/website/html${randomNum}.zip*
			echoContent green " ---> 添加伪装站点成功"
		fi
	else
		randomNum=$((RANDOM%6+1))
		rm -rf /etc/fuckGFW/website/html
		wget -q -P /etc/fuckGFW/website https://raw.githubusercontent.com/linfengzhong/toolbox/main/Website/html${randomNum}.zip >/dev/null
		unzip -o /etc/fuckGFW/website/html${randomNum}.zip -d /etc/fuckGFW/website/html >/dev/null
		rm -f /etc/fuckGFW/website/html${randomNum}.zip*
		echoContent green " ---> 添加伪装站点成功"
	fi
	judge "添加随机伪装站点  "	
}
#-----------------------------------------------------------------------------#
# Upload logs & configuration & dynamic data
function upload_logs_configuration_dynamic_data () {
	#print_info "更新日志、配置文件、动态数据到GitHub "
	github_pull_logserver
	github_push_logserver
	#judge "更新日志、配置文件、动态数据到GitHub "	
}
#-----------------------------------------------------------------------------#
# 主菜单
function menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=============================================================="
	echoContent green "SmartTool：v0.18"
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=============================================================="
	echoContent skyBlue "-------------------------安装软件-----------------------------"
	echoContent yellow "10.安装 全部程序"
	echoContent yellow "11.安装 prerequisite"
	echoContent yellow "12.安装 acme.sh"
	echoContent yellow "13.安装 bpytop"
	echoContent yellow "14.安装 webmin"
	echoContent yellow "15.安装 docker CE"
	echoContent yellow "16.安装 docker compose"
	echoContent yellow "17.安装 git"
	echoContent skyBlue "-------------------------版本控制-----------------------------"  
	echoContent yellow "20.git init | 21.git clone | 22.git pull | 23.git push"
	echoContent skyBlue "-------------------------容器相关-----------------------------"
	echoContent yellow "30.One-key"
	echoContent yellow "31.docker-compose up"
	echoContent yellow "32.docker-compose down"
	echoContent yellow "33.docker status"
	echoContent yellow "34.generate config [Nginx] [Xray] [Trojan-go] [v2ray]"
	echoContent yellow "35.添加随机伪装站点"
	echoContent yellow "36.更新日志、配置文件、动态数据到GitHub"
	echoContent yellow "37.generate docker-compose.yml"
	echoContent skyBlue "-------------------------证书管理-----------------------------"
	echoContent yellow "40.show CA | 41.generate CA | 42.renew CA"	
	echoContent skyBlue "-------------------------科学上网-----------------------------"
	echoContent yellow "50.安装 v2ray-agent | 快捷方式 [vasma] | 51.安装 BBR"	
	echoContent skyBlue "-------------------------脚本管理-----------------------------"
	echoContent yellow "61.generate UUID | 62.show IP | 63.bpytop"	
	echoContent yellow "0.更新脚本 | 9.退出"
	echoContent red "=============================================================="
	mkdirTools
	aliasInstall
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	10)
		install_prerequisite
		install_acme
		install_bpytop
		install_webmin
		install_docker
		install_docker_compose
		install_git
		;;
	11)
		install_prerequisite
		;;
	12)
		install_acme
		;;
	13)
		install_bpytop
		;;
	14)
		install_webmin
		;;
	15)
		install_docker
		;;
	16)
		install_docker_compose
		;;
	17)
		install_git
		;;
	20)
		git_init
		;;
	21)
		git_clone_toolbox
		git_clone_logserver
		;;
	22)
		github_pull_toolbox
		github_pull_logserver
		;;
	23)
		github_push_toolbox
		github_push_logserver
		;;
	30)
		shutdown_docker_compose
		github_pull_toolbox
		github_pull_logserver
		github_push_toolbox
		github_push_logserver
		start_docker_compose
		;;
	31)
		start_docker_compose
		;;
	32)
		shutdown_docker_compose
		;;
	33)
		show_docker_images
		show_docker_container
		;;
	34)
		generate_nginx_conf
		generate_xray_conf
		generate_trojan_go_conf
		generate_v2ray_conf
		;;
	35)
		generate_fake_website
		;;
	36)
		upload_logs_configuration_dynamic_data
		;;
	37)
		generate_docker_compose_yml
		;;
	40)
		checkTLStatus "${currentHost}"
		;;
	41)
		generate_ca
		;;
	42)
		renewalTLS
		;;
	50)
		InstallV2rayAgent
		;;
	51)
		install_bbr
		;;
	61)
		generate_uuid
		;;
	62)
		show_ip
		;;
	63)
		execBpytop
		;;
	0)
		updateSmartTool 1
		;;
	9)
	    exit 0
		;;
	*)
		print_error "请输入正确的数字"
#		menu "$@"
		;;
	esac
}

cleanScreen
initVar $1
cronRenewTLS
menu
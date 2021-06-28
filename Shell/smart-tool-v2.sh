#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-25 [Add new functions] - Stop/Start docker-compose
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#
# 初始化全局变量
function initVar() {

	#-----------------------------------------------------------------------------#
	#定义变量
	WORKDIR="/root/git/toolbox/Docker/docker-compose/k8s-master.ml/"
	GITHUB_REPO="/root/git/toolbox/"
	EMAIL="fred.zhong@outlook.com"
	WEBSITE="k8s-master.ml"
	#-----------------------------------------------------------------------------#
	#fonts color 字体颜色配置
	Red="\033[31m"
	Yellow="\033[33m"
	Blue="\033[36m"
	Green="\033[32m"
	RedBG="\033[41;37m"
	GreenBG="\033[42;37m"
	Font="\033[0m"
	#-----------------------------------------------------------------------------#
	# Notification information 通知信息
	# Info="${Green}[Message信息]${Font}"
	Info="${Green}[Info信息]${Font}"
	OK="${Green}[OK正常]${Font}"
	Error="${Red}[ERROR错误]${Font}"
	#-----------------------------------------------------------------------------#
	
	installType='yum -y install'
	removeType='yum -y remove'
	upgrade="yum -y update"
	echoType='echo -e'

	# 域名
	domain="k8s-master.ml"

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
#打印错误
function print_error() {
	echo -e "${ERROR} ${RedBG} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#判定 成功 or 失败
function judge() {
	if [[ 0 -eq $? ]]; then
		print_ok "$1 <--- 完成"
	else
		print_error "$1 <--- 失败"
		exit 1
	fi
}
#-----------------------------------------------------------------------------#
# 清理屏幕
function cleanUp() {
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
	print_info "Shutdown Docker Compose "
	print_info "关闭 Docker Compose VM "
	cd $WORKDIR
	sudo docker-compose down
	judge "关闭 Docker Compose VM "
}
#-----------------------------------------------------------------------------#
# 启动docker-compose
function start_docker_compose () {
	print_info "启动 Docker Compose "
	cd $WORKDIR
	sudo chmod 777 -R grafana
	sudo chmod 777 -R jenkins
	sudo chmod 777 -R gitea
	sudo docker-compose build
	sudo docker-compose up -d
	judge "启动 Docker Compose "
}
#-----------------------------------------------------------------------------#
# 查看Docker Images
function show_docker_images () {
	sudo docker images
}
#-----------------------------------------------------------------------------#
# 列出所有运行的docker container
function show_docker_container () {
	sudo docker container ps
}
#-----------------------------------------------------------------------------#
# Git global configuration
# https://git-scm.com
#-----------------------------------------------------------------------------#
function git-init () {
	print_info "初始化 Git "
	git config --global user.name "root" 
	git config --global user.email "root@k8s-master.ml"
	git config --global pull.rebase false
	cd ~
	mkdir git
	cd git
	# /root/.ssh/id_rsa
	# /root/.ssh/id_rsa.pub
	ssh-keygen -t rsa -C fred.zhong@outlook.com  
	cat ~/.ssh/id_rsa.pub
	judge "初始化 Git "
}
#-----------------------------------------------------------------------------#
# Git clone toolbox.git
function git-clone-tool-box () {
	print_info "Git clone ToolBox "
	cd  $HOME/git/
	git clone git@github.com:linfengzhong/toolbox.git
	judge "Git clone ToolBox "
}
#-----------------------------------------------------------------------------#
# 同步下载Git文件夹
function github_pull () {
	print_info "更新同步 下载GitHub文件 -> Local Github Repo "
	cd $GITHUB_REPO
	# 查询git repo状态
	sudo git status
	# 暂存未提交的变更 可用来暂存当前正在进行的工作
	# sudo git stash
	# Commit
	sudo git commit -am "update logs"
	# 抽取数据
	sudo git pull
	#sudo git pull --rebase
	#sleep 1
	#sudo cp -rf ~/git/toolbox/Docker/docker-compose/all-in-one/ ~/
	#sleep 1
	#sudo cp -rf ~/git/toolbox/Docker/docker-compose/k8s-master.ml/ ~/
	#sudo chown -R root:root ~/all-in-one/
	#sudo chown -R root:root ~/k8s-master.ml/
	judge "更新同步 下载GitHub文件 -> Local Github Repo "
}
#-----------------------------------------------------------------------------#
# 同步上传Git文件夹
function github_push () {
	print_info "更新同步 上传Local Github Repo -> GitHub文件 "
	cd $GITHUB_REPO
	# 查询git repo状态
	sudo git status
	# 从Git栈中读取最近一次保存的内容
	# sudo git stash pop
	sudo git add .
	sudo git commit -m "sync_all_config_log_data"
	sudo git push
	judge "更新同步 上传Local Github Repo -> GitHub文件 "
	#sleep 1
	#sudo cp -rf ~/git/toolbox/Docker/docker-compose/all-in-one/ ~/
	#sleep 1
	#sudo cp -rf ~/git/toolbox/Docker/docker-compose/k8s-master.ml/ ~/
	#sudo chown -R root:root ~/all-in-one/
	#sudo chown -R root:root ~/k8s-master.ml/
}
#-----------------------------------------------------------------------------#
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
# 查看TLS证书的状态
function checkTLStatus() {
	print_info "网站地址: ${domain}"
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
	crontab -l >/etc/v2ray-agent/backup_crontab.cron
	sed '/v2ray-agent/d;/acme.sh/d' /etc/v2ray-agent/backup_crontab.cron >/etc/v2ray-agent/backup_crontab.cron
	echo "30 1 * * * /bin/bash /etc/v2ray-agent/install.sh RenewTLS" >>/etc/v2ray-agent/backup_crontab.cron
	crontab /etc/v2ray-agent/backup_crontab.cron
	echoContent green "\n ---> 添加定时维护证书成功"
}

#-----------------------------------------------------------------------------#
# 调用
# echoContent green " ---> 检测到证书"
#		checkTLStatus "${tlsDomain}"
#-----------------------------------------------------------------------------#
# 脚本快捷方式
function aliasInstall() {
	if [[ -f "$HOME/smart-tool-v2.sh" ]] && [[ -d "/etc/smart-tool" ]] && grep <$HOME/smart-tool-v2.sh -q "Author: Linfeng Zhong (Fred)"; then
		mv "$HOME/smart-tool-v2.sh" /etc/smart-tool/smart-tool-v2.sh
		if [[ -d "/usr/bin/" ]] && [[ ! -f "/usr/bin/st" ]]; then
			ln -s /etc/smart-tool/smart-tool-v2.sh /usr/bin/st
			chmod 700 /usr/bin/st
			rm -rf "$HOME/smart-tool-v2.sh"
		elif [[ -d "/usr/sbin" ]] && [[ ! -f "/usr/sbin/st" ]]; then
			ln -s /etc/smart-tool/smart-tool-v2.sh /usr/sbin/st
			chmod 700 /usr/sbin/st
			rm -rf "$HOME/smart-tool-v2.sh"
		fi
		echoContent green "快捷方式创建成功，可执行[st]重新打开脚本"
	fi
}
#-----------------------------------------------------------------------------#
# 更新脚本
function updateSmartTool() {

	local version=$(cat /etc/smart-tool/smart-tool-v2.sh | grep '当前版本：v' | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')
	print_info "---> 当前版本:${version}\n"

	local oldVersion=$(cat /etc/smart-tool/smart-tool-v2.sh | grep 'SmartTool：v' | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')
	print_info "---> 更新前版本:${oldVersion}\n"
	
	rm -rf /etc/smart-tool/smart-tool-v2.sh
	echoContent skyBlue "开始下载：\n"
	if wget --help | grep -q show-progress; then
		wget -c -q --show-progress -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v2.sh"
  else
		wget -c -q -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v2.sh"
	fi

	sudo chmod 700 /etc/smart-tool/smart-tool-v2.sh
	local newVersion=$(cat /etc/smart-tool/smart-tool-v2.sh | grep 'SmartTool：v' | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')

	print_info "---> 更新完毕"
	print_info "---> 请手动执行[st]打开脚本"
	print_info "---> 当前版本:${newVersion}\n"
#	echoContent yellow "如更新不成功，请手动执行下面命令"
#	echoContent skyBlue "wget -P /root -N --no-check-certificate\
#  "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v2.sh" &&\
#  chmod 700 /root/smart-tool-v2.sh && /root/smart-tool-v2.sh"
#	echo
	exit 0
}
#-----------------------------------------------------------------------------#
# 初始化安装目录
function mkdirTools() {
	mkdir -p /etc/smart-tool
}
#-----------------------------------------------------------------------------#
# Install acme.sh
#-----------------------------------------------------------------------------#
function install_acme () {
  print_info "Install acme.sh "
  sudo curl https://get.acme.sh | sh -s email=$EMAIL
  judge "安装 acme.sh "
}
#-----------------------------------------------------------------------------#
# Generate CA
#-----------------------------------------------------------------------------#
function generate_ca () {
#  local WEBSITE=$1
  print_info "生成网站证书 "
  print_info "----- 网站证书 ----"
  sudo sh /root/.acme.sh/acme.sh  --issue  -d $WEBSITE --standalone --force
  print_info "----- 网站证书 ----"
  judge "生成网站证书 "
}
#-----------------------------------------------------------------------------#
# Install Git
# https://git-scm.com
#-----------------------------------------------------------------------------#
function install_git () {
	print_info "Install Git "
	sudo yum -y install git
	judge "Install Git "
}
#-----------------------------------------------------------------------------
# Install bpytop
# https://github.com/aristocratos/bpytop
#-----------------------------------------------------------------------------
#PyPi (will always have latest version)
#Install or update to latest version
function install_bpytop () {
	print_info "Install Prerequisites for Python3 "
	sudo yum -y install gcc libffi-devel python3-devel \
                    openssl-devel \
                    automake autoconf libtool make
	judge "Install Prerequisites for Python3 "

	print_info "Install bpytop "
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
#-----------------------------------------------------------------------------#
function install_webmin () {
	print_info "Install webmin "
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
#-----------------------------------------------------------------------------#
function install_docker () {
	print_info "Install Docker CE "
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
#-----------------------------------------------------------------------------#
function install_docker_compose () {
	print_info "Install docker compose "
	sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	docker-compose --version
	judge "Install docker compose "
}
#-----------------------------------------------------------------------------#
# Install Prerequisite
#-----------------------------------------------------------------------------#
# 安装必要程序
function install_prerequisite () {
  print_info "安装 wget lsof tar unzip curl socat "
  yum -y install wget lsof tar unzip curl socat
  judge "安装 wget lsof tar unzip curl socat "
}
#-----------------------------------------------------------------------------#
# Show IP
#-----------------------------------------------------------------------------#
# 外部IP
function show_ip () {
	print_info "服务器外部 IP: "
	local zIP=$(curl -s https://ipinfo.io/ip)
	print_info $zIP
}
#-----------------------------------------------------------------------------#
#===== RHEL 7/8 | CentOS 7/8 | Rocky Linux 8 =====
#-----------------------------------------------------------------------------#
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
#-----------------------------------------------------------------------------#
function turn_off_selinux () {
  print_info "开始配置 Linux Rocky 8.4 / CentOS 8 服务器"
  sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0
  #judge "Step 1: Security-Enhanced Linux"
  print_info "Security-Enhanced Linux <--- 完成"
}
#-----------------------------------------------------------------------------#
# 主菜单
function menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=============================================================="
	echoContent green "SmartTool：v0.043"
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "初始化服务器、安装Docker、执行容器"
	echoContent green "当前系统Linux 版本 : \c" 
	checkSystem
	echoContent red "=============================================================="
	echoContent skyBlue "-------------------------安装软件-----------------------------"
	echoContent yellow "10.安装 全部程序"	
	echoContent yellow "11.安装 prerequisite"
	echoContent yellow "14.安装 acme.sh"
	echoContent yellow "15.安装 bpytop"
	echoContent yellow "16.安装 Webmin"
	echoContent yellow "17.安装 Docker CE"
	echoContent yellow "18.安装 Docker compose"
	echoContent yellow "19.安装 Git"
	echoContent skyBlue "-------------------------版本控制-----------------------------"  
	echoContent yellow "21.git-init"
	echoContent yellow "22.git-pull"
	echoContent yellow "23.git-push"
	echoContent yellow "24.git-clone"
	echoContent skyBlue "-------------------------容器相关-----------------------------"
	echoContent yellow "31.docker-compose up"
	echoContent yellow "32.docker-compose down"
	echoContent yellow "33.One-key"
	echoContent yellow "34.docker status"
	echoContent skyBlue "-------------------------工具管理-----------------------------"
	echoContent yellow "41.show IP"	
	echoContent yellow "42.show CA status"	
	echoContent yellow "43.generate CA"	
	echoContent skyBlue "-------------------------脚本管理-----------------------------"
	echoContent yellow "00.更新脚本"
	echoContent yellow "14.查看日志"
	echoContent yellow "15.卸载脚本"
	echoContent yellow "97.检查系统版本"
	echoContent yellow "98.bpytop"
	echoContent yellow "99.退出"
	echoContent red "=============================================================="
	mkdirTools
	aliasInstall
	read -r -p "Please choose the function(请选择): " selectInstallType
	case ${selectInstallType} in
	1)
		selectCoreInstall
		;;
	2)
		selectCoreInstall
		;;
	3)
		manageAccount 1
		;;
	4)
		updateNginxBlog 1
		;;
	5)
		renewalTLS 1
		;;
	6)
		updateV2RayCDN 1
		;;
	7)
		ipv6Routing 1
		;;
	8)
		streamingToolbox 1
		;;
	9)
		addCorePort 1
		;;
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
	13)
		bbrInstall
		;;
	14)
		install_acme
		;;
	15)
		install_bpytop
		;;
	16)
		install_webmin
		;;
	17)
		install_docker
		;;
	18)
		install_docker_compose
		;;
	19)
		install_git
		;;	
	21)
		git-init
		;;
	22)
		github_pull
		;;
	23)
		github_push
		;;
	24)
		git-clone-tool-box
		;;
	31)
		start_docker_compose
		;;
	32)
		shutdown_docker_compose
		;;
	33)
		shutdown_docker_compose
		github_pull
		github_push
		start_docker_compose
		;;
	34)
		show_docker_images
		show_docker_container
		;;
	41)
		show_ip
		;;
	42)
		checkTLStatus "${domain}"
		;;
	43)
		generate_ca
		;;
	97)
		checkSystem
		;;
	98)
		execBpytop
		;;	
	99)
	    exit 0
		;;
	00)
		updateSmartTool 1
		;;
	*)
		print_error "请输入正确的数字"
#		menu "$@"
		;;
	esac
}

cleanUp
initVar $1
#readInstallType
#readInstallProtocolType
#readConfigHostPathUUID
menu "$@"

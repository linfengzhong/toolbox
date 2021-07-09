#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-25 [Add new functions] - Stop/Start docker-compose
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#
#===== RHEL 7/8 | CentOS 7/8 | Rocky Linux 8 =====
#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#
# 初始化全局变量
export LANG=en_US.UTF-8
function initVar() {

	#定义变量
	WORKDIR="/root/git/toolbox/Docker/docker-compose/k8s-master.ml/"
	GITHUB_REPO="/root/git/toolbox/"
	EMAIL="fred.zhong@outlook.com"

	# 网站 域名 配置文件的host
	WEBSITE="k8s-master.ml"
	domain="k8s-master.ml"
	currentHost="k8s-master.ml"

	#fonts color 字体颜色配置
	Red="\033[31m"
	Yellow="\033[33m"
	Blue="\033[36m"
	Green="\033[32m"
	RedBG="\033[41;37m"
	GreenBG="\033[42;37m"
	Font="\033[0m"

	# Notification information 通知信息
	# Info="${Green}[Message信息]${Font}"
	Info="${Green}[Info信息]${Font}"
	OK="${Green}[OK正常]${Font}"
	Error="${Red}[ERROR错误]${Font}"
	
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
# Install acme.sh
function install_acme () {
  print_info "Install acme.sh "
  sudo curl https://get.acme.sh | sh -s email=$EMAIL
  judge "安装 acme.sh "
}
#-----------------------------------------------------------------------------#
# Generate CA
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
function install_git () {
	print_info "Install Git "
	sudo yum -y install git
	judge "Install Git "
}
#-----------------------------------------------------------------------------#
# Install bpytop
# https://github.com/aristocratos/bpytop
# PyPi (will always have latest version)
# Install or update to latest version
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
# 安装必要程序
function install_prerequisite () {
	print_info "安装 wget lsof tar unzip curl socat "
	yum -y install wget lsof tar unzip curl socat
	judge "安装 wget lsof tar unzip curl socat "
}
#-----------------------------------------------------------------------------#
# 安装BBR
function install_bbr() {
	echoContent red "\n=============================================================="
	echoContent green "BBR、DD脚本用的[ylx2016]的成熟作品，地址[https://github.com/ylx2016/Linux-NetSpeed]，请熟知"
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
function git_clone_tool_box () {
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
		echoContent white "Rocky 8.4"

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
# 更新证书
renewalTLS() {
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
			# handleNginx stop
			# sudo "$HOME/.acme.sh/acme.sh" --cron --home "$HOME/.acme.sh"
			# sudo "$HOME/.acme.sh/acme.sh" --installcert -d "${currentHost}" --fullchainpath /etc/v2ray-agent/tls/"${currentHost}.crt" --keypath /etc/v2ray-agent/tls/"${currentHost}.key"
			# handleNginx start

			#reloadCore

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
		wget -c -q --show-progress -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v3.sh"
  	else
		wget -c -q -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v3.sh"
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

	mkdir -p /etc/fuckGFW/tls
	mkdir -p /etc/fuckGFW/mtg
	mkdir -p /etc/fuckGFW/subscribe
	mkdir -p /etc/fuckGFW/subscribe_tmp
	mkdir -p /etc/fuckGFW/v2ray/conf
	mkdir -p /etc/fuckGFW/xray/conf
	mkdir -p /etc/fuckGFW/trojan
	mkdir -p /etc/systemd/system/
	mkdir -p /tmp/fuckGFW-tls/

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
# 查看、检查日志
checkLog() {
	if [[ -z ${configPath} ]]; then
		echoContent red " ---> 没有检测到安装目录，请执行脚本安装内容"
	fi
	local logStatus=false
	if [[ -n $(cat ${configPath}00_log.json | grep access) ]]; then
		logStatus=true
	fi

	echoContent skyBlue "\n功能 $1/${totalProgress} : 查看日志"
	echoContent red "\n=============================================================="
	echoContent yellow "# 建议仅调试时打开access日志\n"

	if [[ "${logStatus}" == "false" ]]; then
		echoContent yellow "1.打开access日志"
	else
		echoContent yellow "1.关闭access日志"
	fi

	echoContent yellow "2.监听access日志"
	echoContent yellow "3.监听error日志"
	echoContent yellow "4.清空日志"
	echoContent red "=============================================================="

	read -r -p "请选择：" selectAccessLogType
	local configPathLog=${configPath//conf\//}

	case ${selectAccessLogType} in
	1)
		if [[ "${logStatus}" == "false" ]]; then
			cat <<EOF >${configPath}00_log.json
{
  "log": {
  	"access":"${configPathLog}access.log",
    "error": "${configPathLog}error.log",
    "loglevel": "warning"
  }
}
EOF
		elif [[ "${logStatus}" == "true" ]]; then
			cat <<EOF >${configPath}00_log.json
{
  "log": {
    "error": "${configPathLog}error.log",
    "loglevel": "warning"
  }
}
EOF
		fi
		reloadCore
		checkLog 1
		;;
	2)
		tail -f ${configPathLog}access.log
		;;
	3)
		tail -f ${configPathLog}error.log
		;;
	4)
		echo >${configPathLog}access.log
		echo >${configPathLog}error.log
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 安装Trojan-go
installTrojanGo() {
	echoContent skyBlue "安装Trojan-Go "

	if ! ls /etc/fuckGFW/trojan/ | grep -q trojan-go; then
		version=$(curl -s https://github.com/p4gefau1t/trojan-go/releases | grep /trojan-go/releases/tag/ | head -1 | awk -F "[/]" '{print $6}' | awk -F "[>]" '{print $2}' | awk -F "[<]" '{print $1}')
		echoContent green " ---> Trojan-Go版本:${version}"
		if wget --help | grep -q show-progress; then
			wget -c -q --show-progress -P /etc/fuckGFW/trojan/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/trojan-go-linux-amd64.zip"
		else
			wget -c -P /etc/fuckGFW/trojan/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/trojan-go-linux-amd64.zip" >/dev/null 2>&1
		fi
		unzip -o /etc/fuckGFW/trojan/trojan-go-linux-amd64.zip -d /etc/fuckGFW/trojan >/dev/null
		rm -rf /etc/fuckGFW/trojan/trojan-go-linux-amd64.zip
	else
		echoContent green " ---> Trojan-Go版本:$(/etc/fuckGFW/trojan/trojan-go --version | awk '{print $2}' | head -1)"

		read -r -p "是否重新安装？[y/n]:" reInstallTrojanStatus
		if [[ "${reInstallTrojanStatus}" == "y" ]]; then
			rm -rf /etc/fuckGFW/trojan/trojan-go*
			installTrojanGo
		fi
	fi
}
#-----------------------------------------------------------------------------#
# 更新Trojan-Go
updateTrojanGo() {
	echoContent skyBlue "更新Trojan-Go "
	if [[ ! -d "/etc/fuckGFW/trojan/" ]]; then
		echoContent red " ---> 没有检测到安装目录，请执行脚本安装内容"
		menu
		exit 0
	fi
	if find /etc/fuckGFW/trojan/ | grep -q "trojan-go"; then
		version=$(curl -s https://github.com/p4gefau1t/trojan-go/releases | grep /trojan-go/releases/tag/ | head -1 | awk -F "[/]" '{print $6}' | awk -F "[>]" '{print $2}' | awk -F "[<]" '{print $1}')
		echoContent green " ---> Trojan-Go版本:${version}"
		if [[ -n $(wget --help | grep show-progress) ]]; then
			wget -c -q --show-progress -P /etc/fuckGFW/trojan/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/trojan-go-linux-amd64.zip"
		else
			wget -c -P /etc/fuckGFW/trojan/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/trojan-go-linux-amd64.zip" >/dev/null 2>&1
		fi
		unzip -o /etc/fuckGFW/trojan/trojan-go-linux-amd64.zip -d /etc/fuckGFW/trojan >/dev/null
		rm -rf /etc/fuckGFW/trojan/trojan-go-linux-amd64.zip
		handleTrojanGo stop
		handleTrojanGo start
	else
		echoContent green " ---> 当前Trojan-Go版本:$(/etc/fuckGFW/trojan/trojan-go --version | awk '{print $2}' | head -1)"
		if [[ -n $(/etc/fuckGFW/trojan/trojan-go --version) ]]; then
			version=$(curl -s https://github.com/p4gefau1t/trojan-go/releases | grep /trojan-go/releases/tag/ | head -1 | awk -F "[/]" '{print $6}' | awk -F "[>]" '{print $2}' | awk -F "[<]" '{print $1}')
			if [[ "${version}" == "$(/etc/fuckGFW/trojan/trojan-go --version | awk '{print $2}' | head -1)" ]]; then
				read -r -p "当前版本与最新版相同，是否重新安装？[y/n]:" reInstalTrojanGoStatus
				if [[ "${reInstalTrojanGoStatus}" == "y" ]]; then
					handleTrojanGo stop
					rm -rf /etc/fuckGFW/trojan/trojan-go
					updateTrojanGo 1
				else
					echoContent green " ---> 放弃重新安装"
				fi
			else
				read -r -p "最新版本为：${version}，是否更新？[y/n]：" installTrojanGoStatus
				if [[ "${installTrojanGoStatus}" == "y" ]]; then
					rm -rf /etc/fuckGFW/trojan/trojan-go
					updateTrojanGo 1
				else
					echoContent green " ---> 放弃更新"
				fi
			fi
		fi
	fi
}
#-----------------------------------------------------------------------------#
# 操作Trojan-Go
handleTrojanGo() {
	if [[ -n $(find /bin /usr/bin -name "systemctl") ]] && ls /etc/systemd/system/ | grep -q trojan-go.service; then
		if [[ -z $(pgrep -f "trojan-go") ]] && [[ "$1" == "start" ]]; then
			systemctl start trojan-go.service
		elif [[ -n $(pgrep -f "trojan-go") ]] && [[ "$1" == "stop" ]]; then
			systemctl stop trojan-go.service
		fi
	fi

	sleep 0.5
	if [[ "$1" == "start" ]]; then
		if [[ -n $(pgrep -f "trojan-go") ]]; then
			echoContent green " ---> Trojan-Go启动成功"
		else
			echoContent red "Trojan-Go启动失败"
			echoContent red "请手动执行【/etc/fuckGFW/trojan/trojan-go -config /etc/fuckGFW/trojan/config_full.json】,查看错误日志"
			exit 0
		fi
	elif [[ "$1" == "stop" ]]; then
		if [[ -z $(pgrep -f "trojan-go") ]]; then
			echoContent green " ---> Trojan-Go关闭成功"
		else
			echoContent red "Trojan-Go关闭失败"
			echoContent red "请手动执行【ps -ef|grep -v grep|grep trojan-go|awk '{print \$2}'|xargs kill -9】"
			exit 0
		fi
	fi
}
# 清理旧残留
cleanUp() {
	if [[ "$1" == "v2rayClean" ]]; then
		rm -rf "$(find /etc/fuckGFW/v2ray/* | grep -E '(config_full.json|conf)')"
		handleV2Ray stop >/dev/null
		rm -f /etc/systemd/system/v2ray.service
	elif [[ "$1" == "xrayClean" ]]; then
		rm -rf "$(find /etc/fuckGFW/xray/* | grep -E '(config_full.json|conf)')"
		handleXray stop >/dev/null
		rm -f /etc/systemd/system/xray.service

	elif [[ "$1" == "v2rayDel" ]]; then
		rm -rf /etc/fuckGFW/v2ray/*

	elif [[ "$1" == "xrayDel" ]]; then
		rm -rf /etc/fuckGFW/xray/*
	fi
}
# 安装工具包
installTools() {
	echo '安装工具'
	echoContent skyBlue "\n进度  $1/${totalProgress} : 安装工具"
	# 修复ubuntu个别系统问题
	if [[ "${release}" == "ubuntu" ]]; then
		dpkg --configure -a
	fi

	if [[ -n $(pgrep -f "apt") ]]; then
		pgrep -f apt | xargs kill -9
	fi

	echoContent green " ---> 检查、安装更新【新机器会很慢，如长时间无反应，请手动停止后重新执行】"

	${upgrade} >/dev/null 2>&1
	if [[ "${release}" == "centos" ]]; then
		rm -rf /var/run/yum.pid
		${installType} epel-release >/dev/null 2>&1
	fi

	#	[[ -z `find /usr/bin /usr/sbin |grep -v grep|grep -w curl` ]]

	if ! find /usr/bin /usr/sbin | grep -q -w wget; then
		echoContent green " ---> 安装wget"
		${installType} wget >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w curl; then
		echoContent green " ---> 安装curl"
		${installType} curl >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w unzip; then
		echoContent green " ---> 安装unzip"
		${installType} unzip >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w socat; then
		echoContent green " ---> 安装socat"
		${installType} socat >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w tar; then
		echoContent green " ---> 安装tar"
		${installType} tar >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w cron; then
		echoContent green " ---> 安装crontabs"
		if [[ "${release}" == "ubuntu" ]] || [[ "${release}" == "debian" ]]; then
			${installType} cron >/dev/null 2>&1
		else
			${installType} crontabs >/dev/null 2>&1
		fi
	fi
	if ! find /usr/bin /usr/sbin | grep -q -w jq; then
		echoContent green " ---> 安装jq"
		${installType} jq >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w binutils; then
		echoContent green " ---> 安装binutils"
		${installType} binutils >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w ping6; then
		echoContent green " ---> 安装ping6"
		${installType} inetutils-ping >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w qrencode; then
		echoContent green " ---> 安装qrencode"
		${installType} qrencode >/dev/null 2>&1
	fi

    if ! find /usr/bin /usr/sbin | grep -q -w sudo; then
		echoContent green " ---> 安装sudo"
		${installType} sudo >/dev/null 2>&1
	fi

	if ! find /usr/bin /usr/sbin | grep -q -w lsb-release; then
		echoContent green " ---> 安装lsb-release"
		${installType} lsb-release >/dev/null 2>&1
	fi

	# 检测nginx版本，并提供是否卸载的选项

	if ! find /usr/bin /usr/sbin | grep -q -w nginx; then
		echoContent green " ---> 安装nginx"
		installNginxTools
	else
		nginxVersion=$(nginx -v 2>&1)
		nginxVersion=$(echo "${nginxVersion}" | awk -F "[n][g][i][n][x][/]" '{print $2}' | awk -F "[.]" '{print $2}')
		if [[ ${nginxVersion} -lt 14 ]]; then
			read -r -p "读取到当前的Nginx版本不支持gRPC，会导致安装失败，是否卸载Nginx后重新安装 ？[y/n]:" unInstallNginxStatus
			if [[ "${unInstallNginxStatus}" == "y" ]]; then
				${removeType} nginx >/dev/null 2>&1
				echoContent yellow " ---> nginx卸载完成"
				echoContent green " ---> 安装nginx"
				installNginxTools >/dev/null 2>&1
			else
				exit 0
			fi
		fi
	fi
	if ! find /usr/bin /usr/sbin | grep -q -w semanage; then
		echoContent green " ---> 安装semanage"
		${installType} bash-completion >/dev/null 2>&1

		if [[ "${centosVersion}" == "7" ]]; then
			policyCoreUtils="policycoreutils-python.x86_64"
		elif [[ "${centosVersion}" == "8" ]]; then
			policyCoreUtils="policycoreutils-python-utils-2.9-9.el8.noarch"
		fi

		if [[ -n "${policyCoreUtils}" ]]; then
			${installType} ${policyCoreUtils} >/dev/null 2>&1
		fi
		if [[ -n $(which semanage) ]]; then
			semanage port -a -t http_port_t -p tcp 31300

		fi
	fi

	# todo 关闭防火墙

	if [[ ! -d "$HOME/.acme.sh" ]] || [[ -d "$HOME/.acme.sh" && -z $(find "$HOME/.acme.sh/acme.sh") ]]; then
		echoContent green " ---> 安装acme.sh"
		curl -s https://get.acme.sh | sh -s email=my@example.com >/etc/v2ray-agent/tls/acme.log 2>&1
		if [[ ! -d "$HOME/.acme.sh" ]] || [[ -z $(find "$HOME/.acme.sh/acme.sh") ]]; then
			echoContent red "  acme安装失败--->"
			tail -n 100 /etc/v2ray-agent/tls/acme.log
			echoContent yellow "错误排查："
			echoContent red "  1.获取Github文件失败，请等待Gitub恢复后尝试，恢复进度可查看 [https://www.githubstatus.com/]"
			echoContent red "  2.acme.sh脚本出现bug，可查看[https://github.com/acmesh-official/acme.sh] issues"
			exit 0
		fi
	fi
}

# 安装Nginx
installNginxTools() {

	if [[ "${release}" == "debian" ]]; then
		# 卸载原有Nginx
		# sudo apt remove nginx nginx-common nginx-full -y >/dev/null
		sudo apt install gnupg2 ca-certificates lsb-release -y >/dev/null 2>&1
		echo "deb http://nginx.org/packages/mainline/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list >/dev/null 2>&1
		echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx >/dev/null 2>&1
		curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key >/dev/null 2>&1
		# gpg --dry-run --quiet --import --import-options import-show /tmp/nginx_signing.key
		sudo mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
		sudo apt update >/dev/null 2>&1

	elif [[ "${release}" == "ubuntu" ]]; then
		# 卸载原有Nginx
		# sudo apt remove nginx nginx-common nginx-full -y >/dev/null
		sudo apt install gnupg2 ca-certificates lsb-release -y >/dev/null 2>&1
		echo "deb http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list >/dev/null 2>&1
		echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx >/dev/null 2>&1
		curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key >/dev/null 2>&1
		# gpg --dry-run --quiet --import --import-options import-show /tmp/nginx_signing.key
		sudo mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
		sudo apt update >/dev/null 2>&1

	elif [[ "${release}" == "centos" ]]; then
		${installType} yum-utils >/dev/null 2>&1
		cat <<EOF >/etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
		sudo yum-config-manager --enable nginx-mainline >/dev/null 2>&1
	fi
	${installType} nginx >/dev/null 2>&1
	systemctl daemon-reload
	systemctl enable nginx
}
# 初始化Nginx申请证书配置
initTLSNginxConfig() {
	handleNginx stop
	echoContent skyBlue "\n进度  $1/${totalProgress} : 初始化Nginx申请证书配置"
	if [[ -n "${currentHost}" ]]; then
		echo
		read -r -p "读取到上次安装记录，是否使用上次安装时的域名 ？[y/n]:" historyDomainStatus
		if [[ "${historyDomainStatus}" == "y" ]]; then
			domain=${currentHost}
			echoContent yellow "\n ---> 域名：${domain}"
		else
			echo
			echoContent yellow "请输入要配置的域名 例：www.v2ray-agent.com --->"
			read -r -p "域名:" domain
		fi
	else
		echo
		echoContent yellow "请输入要配置的域名 例：www.v2ray-agent.com --->"
		read -r -p "域名:" domain
	fi

	if [[ -z ${domain} ]]; then
		echoContent red "  域名不可为空--->"
		initTLSNginxConfig
	else
		# 修改配置
		echoContent green "\n ---> 配置Nginx"
		touch /etc/nginx/conf.d/alone.conf
		echo "server {listen 80;listen [::]:80;server_name ${domain};root /usr/share/nginx/html;location ~ /.well-known {allow all;}location /test {return 200 'fjkvymb6len';}}" >/etc/nginx/conf.d/alone.conf
		# 启动nginx
		handleNginx start
		echoContent yellow "\n检查IP是否设置为当前VPS"
		checkIP
		# 测试nginx
		echoContent yellow "\n检查Nginx是否正常访问"
		sleep 0.5
		domainResult=$(curl -s "${domain}/test" --resolve "${domain}:80:${pingIP}" | grep fjkvymb6len)
		if [[ -n ${domainResult} ]]; then
			handleNginx stop
			echoContent green "\n ---> Nginx配置成功"
		else
			echoContent red " ---> 无法正常访问服务器，请检测域名是否正确、域名的DNS解析以及防火墙设置是否正确--->"
			exit 0
		fi
	fi
}
# 安装TLS
installTLS() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 申请TLS证书\n"
	local tlsDomain=${domain}
	# 安装tls
	if [[ -f "/etc/v2ray-agent/tls/${tlsDomain}.crt" && -f "/etc/v2ray-agent/tls/${tlsDomain}.key" && -n $(cat "/etc/v2ray-agent/tls/${tlsDomain}.crt") ]] || [[ -d "$HOME/.acme.sh/${tlsDomain}_ecc" && -f "$HOME/.acme.sh/${tlsDomain}_ecc/${tlsDomain}.key" && -f "$HOME/.acme.sh/${tlsDomain}_ecc/${tlsDomain}.cer" ]]; then
		# 存在证书
		echoContent green " ---> 检测到证书"
		checkTLStatus "${tlsDomain}"
		if [[ "${tlsStatus}" == "已过期" ]]; then
			rm -rf $HOME/.acme.sh/${tlsDomain}_ecc/*
			rm -rf /etc/v2ray-agent/tls/${tlsDomain}*
			installTLS "$1"
		else
			echoContent green " ---> 证书有效"

			if ! ls /etc/v2ray-agent/tls/ | grep -q "${tlsDomain}.crt" || ! ls /etc/v2ray-agent/tls/ | grep -q "${tlsDomain}.key" || [[ -z $(cat "/etc/v2ray-agent/tls/${tlsDomain}.crt") ]]; then
				sudo "$HOME/.acme.sh/acme.sh" --installcert -d "${tlsDomain}" --fullchainpath "/etc/v2ray-agent/tls/${tlsDomain}.crt" --keypath "/etc/v2ray-agent/tls/${tlsDomain}.key" --ecc >/dev/null
			else
				echoContent yellow " ---> 如未过期请选择[n]\n"
				read -r -p "是否重新安装？[y/n]:" reInstallStatus
				if [[ "${reInstallStatus}" == "y" ]]; then
					rm -rf /etc/v2ray-agent/tls/*
					installTLS "$1"
				fi
			fi
		fi
	elif [[ -d "$HOME/.acme.sh" ]] && [[ ! -f "$HOME/.acme.sh/${tlsDomain}_ecc/${tlsDomain}.cer" || ! -f "$HOME/.acme.sh/${tlsDomain}_ecc/${tlsDomain}.key" ]]; then
		echoContent green " ---> 安装TLS证书"
		if [[ -n "${pingIPv6}" ]]; then
			sudo "$HOME/.acme.sh/acme.sh" --issue -d "${tlsDomain}" --standalone -k ec-256 --listen-v6 >> /etc/v2ray-agent/tls/acme.log
		else
			sudo "$HOME/.acme.sh/acme.sh" --issue -d "${tlsDomain}" --standalone -k ec-256 >> /etc/v2ray-agent/tls/acme.log
		fi

		if [[ -d "$HOME/.acme.sh/${tlsDomain}_ecc" && -f "$HOME/.acme.sh/${tlsDomain}_ecc/${tlsDomain}.key" && -f "$HOME/.acme.sh/${tlsDomain}_ecc/${tlsDomain}.cer" ]]; then
			sudo "$HOME/.acme.sh/acme.sh" --installcert -d "${tlsDomain}" --fullchainpath "/etc/v2ray-agent/tls/${tlsDomain}.crt" --keypath "/etc/v2ray-agent/tls/${tlsDomain}.key" --ecc >/dev/null
		fi

		if [[ ! -f "/etc/v2ray-agent/tls/${tlsDomain}.crt" || ! -f "/etc/v2ray-agent/tls/${tlsDomain}.key"  ]] || [[ -z $(cat "/etc/v2ray-agent/tls/${tlsDomain}.key") || -z $(cat "/etc/v2ray-agent/tls/${tlsDomain}.crt") ]]; then
			tail -n 10 /etc/v2ray-agent/tls/acme.log
			echoContent red " ---> TLS安装失败，请检查acme日志"
			exit 0
		fi
		echoContent green " ---> TLS生成成功"
	else
		echoContent yellow " ---> 未安装acme.sh"
		exit 0
	fi
}
# 操作Nginx
handleNginx() {

	if [[ -z $(pgrep -f "nginx") ]] && [[ "$1" == "start" ]]; then
		nginx
		sleep 0.5
		if ! ps -ef | grep -v grep | grep -q nginx; then
			echoContent red " ---> Nginx启动失败"
			echoContent red " ---> 请手动尝试安装nginx后，再次执行脚本"
			exit 0
		fi
	elif [[ "$1" == "stop" ]] && [[ -n $(pgrep -f "nginx") ]]; then
		nginx -s stop >/dev/null 2>&1
		sleep 0.5
		if [[ -n $(pgrep -f "nginx") ]]; then
			pgrep -f "nginx" | xargs kill -9
		fi
	fi
}
# 配置伪装博客
initNginxConfig() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 配置Nginx"

	cat <<EOF >/etc/nginx/conf.d/alone.conf
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    root /usr/share/nginx/html;
    location ~ /.well-known {allow all;}
    location /test {return 200 'fjkvymb6len';}
}
EOF
}
# 自定义/随机路径
randomPathFunction() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 生成随机路径"

	if [[ -n "${currentPath}" ]]; then
		echo
		read -r -p "读取到上次安装记录，是否使用上次安装时的path路径 ？[y/n]:" historyPathStatus
		echo
	fi

	if [[ "${historyPathStatus}" == "y" ]]; then
		customPath=${currentPath}
		echoContent green " ---> 使用成功\n"
	else
		echoContent yellow "请输入自定义路径[例: alone]，不需要斜杠，[回车]随机路径"
		read -r -p '路径:' customPath

		if [[ -z "${customPath}" ]]; then
			customPath=$(head -n 50 /dev/urandom | sed 's/[^a-z]//g' | strings -n 4 | tr 'A-Z' 'a-z' | head -1)
			currentPath=${customPath:0:4}
			customPath=${currentPath}
		else
			currentPath=${customPath}
		fi

	fi
	echoContent yellow "path：${currentPath}"
	echoContent skyBlue "\n----------------------------"
}
# 安装xray
installXray() {
	readInstallType
	echoContent skyBlue "\n进度  $1/${totalProgress} : 安装Xray"

	if [[ "${coreInstallType}" != "1" ]]; then

		version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | jq -r .[].tag_name|head -1)

		echoContent green " ---> Xray-core版本:${version}"
		if wget --help | grep -q show-progress; then
			wget -c -q --show-progress -P /etc/v2ray-agent/xray/ "https://github.com/XTLS/Xray-core/releases/download/${version}/${xrayCoreCPUVendor}.zip"
		else
			wget -c -P /etc/v2ray-agent/xray/ "https://github.com/XTLS/Xray-core/releases/download/${version}/${xrayCoreCPUVendor}.zip" >/dev/null 2>&1
		fi

		unzip -o /etc/v2ray-agent/xray/${xrayCoreCPUVendor}.zip -d /etc/v2ray-agent/xray >/dev/null
		rm -rf /etc/v2ray-agent/xray/${xrayCoreCPUVendor}.zip
		chmod 655 /etc/v2ray-agent/xray/xray
	else
		echoContent green " ---> Xray-core版本:$(/etc/v2ray-agent/xray/xray --version | awk '{print $2}' | head -1)"
		read -r -p "是否更新、升级？[y/n]:" reInstallXrayStatus
		if [[ "${reInstallXrayStatus}" == "y" ]]; then
			rm -f /etc/v2ray-agent/xray/xray
			installXray "$1"
		fi
	fi
}
# Xray开机自启
installXrayService() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 配置Xray开机自启"
	if [[ -n $(find /bin /usr/bin -name "systemctl") ]]; then
		rm -rf /etc/systemd/system/xray.service
		touch /etc/systemd/system/xray.service
		execStart='/etc/v2ray-agent/xray/xray run -confdir /etc/v2ray-agent/xray/conf'
		cat <<EOF >/etc/systemd/system/xray.service
[Unit]
Description=Xray - A unified platform for anti-censorship
# Documentation=https://v2ray.com https://guide.v2fly.org
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=yes
ExecStart=${execStart}
Restart=on-failure
RestartPreventExitStatus=23


[Install]
WantedBy=multi-user.target
EOF
		systemctl daemon-reload
		systemctl enable xray.service
		echoContent green " ---> 配置Xray开机自启成功"
	fi
}
# 自定义CDN IP
customCDNIP() {
	echoContent skyBlue "\n进度 $1/${totalProgress} : 添加DNS智能解析"
	echoContent yellow "\n如对Cloudflare自选ip不了解，请选择[n]"
	echoContent yellow "\n 移动:104.16.123.96"
	echoContent yellow " 联通:hostmonit.com"
	echoContent yellow " 电信:www.digitalocean.com"
	echoContent skyBlue "----------------------------"
	read -r -p '是否使用？[y/n]:' dnsProxy
	if [[ "${dnsProxy}" == "y" ]]; then
		add="domain08.mqcjuc.ml"
		echoContent green "\n ---> 使用成功"
	else
		add="${domain}"
	fi
}
# 初始化Xray 配置文件
initXrayConfig() {
	echoContent skyBlue "\n进度 $2/${totalProgress} : 初始化Xray配置"
	echo
	read -r -p "是否自定义UUID ？[y/n]:" customUUIDStatus
	echo

	if [[ "${customUUIDStatus}" == "y" ]]; then
		read -r -p "请输入合法的UUID:" currentCustomUUID
		if [[ -n "${currentCustomUUID}" ]]; then
			uuid=${currentCustomUUID}
		fi
	fi

	if [[ -n "${currentUUID}" && -z "${uuid}" ]]; then
		read -r -p "读取到上次安装记录，是否使用上次安装时的UUID ？[y/n]:" historyUUIDStatus
		if [[ "${historyUUIDStatus}" == "y" ]]; then
			uuid=${currentUUID}
		else
			uuid=$(/etc/v2ray-agent/xray/xray uuid)
		fi
	elif [[ -z "${uuid}" ]]; then
		uuid=$(/etc/v2ray-agent/xray/xray uuid)
	fi

	if [[ -z "${uuid}" ]]; then
		echoContent red "\n ---> uuid读取错误，重新生成"
		uuid=$(/etc/v2ray-agent/xray/xray uuid)
	fi

	echoContent green "\n ---> 使用成功"

	rm -rf /etc/v2ray-agent/xray/conf/*

	# log
	cat <<EOF >/etc/v2ray-agent/xray/conf/00_log.json
{
  "log": {
    "error": "/etc/v2ray-agent/xray/error.log",
    "loglevel": "warning"
  }
}
EOF

	# outbounds
	if [[ -n "${pingIPv6}" ]]; then
		cat <<EOF >/etc/v2ray-agent/xray/conf/10_ipv6_outbounds.json
{
    "outbounds": [
        {
          "protocol": "freedom",
          "settings": {},
          "tag": "direct"
        }
    ]
}
EOF

	else
		cat <<EOF >/etc/v2ray-agent/xray/conf/10_ipv4_outbounds.json
{
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
    ]
}
EOF
	fi

	# dns
	cat <<EOF >/etc/v2ray-agent/xray/conf/11_dns.json
{
    "dns": {
        "servers": [
          "localhost"
        ]
  }
}
EOF

	# VLESS_TCP_TLS/XTLS
	# 回落nginx
	local fallbacksList='{"dest":31300,"xver":0},{"alpn":"h2","dest":31302,"xver":0}'

	# trojan
	if [[ -n $(echo "${selectCustomInstallType}" | grep 4) || "$1" == "all" ]]; then
#		fallbacksList=${fallbacksList}',{"path":"/'${customPath}'tcp","dest":31298,"xver":1}'
		fallbacksList='{"dest":31296,"xver":1},{"alpn":"h2","dest":31302,"xver":0}'
		cat <<EOF >/etc/v2ray-agent/xray/conf/04_trojan_TCP_inbounds.json
{
"inbounds":[
	{
	  "port": 31296,
	  "listen": "127.0.0.1",
	  "protocol": "trojan",
	  "tag":"trojanTCP",
	  "settings": {
		"clients": [
		  {
			"password": "${uuid}",
			"email": "${domain}_trojan_tcp"
		  }
		],
		"fallbacks":[
			{"dest":"31300"}
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
	]
}
EOF
	fi

#	if echo "${selectCustomInstallType}" | grep -q 4 || [[ "$1" == "all" ]]; then
#		# 回落trojan-go
#		fallbacksList='{"dest":31296,"xver":0},{"alpn":"h2","dest":31302,"xver":0}'
#	fi

	# VLESS_WS_TLS
	if echo "${selectCustomInstallType}" | grep -q 1 || [[ "$1" == "all" ]]; then
		fallbacksList=${fallbacksList}',{"path":"/'${customPath}'ws","dest":31297,"xver":1}'
		cat <<EOF >/etc/v2ray-agent/xray/conf/03_VLESS_WS_inbounds.json
{
"inbounds":[
    {
  "port": 31297,
  "listen": "127.0.0.1",
  "protocol": "vless",
  "tag":"VLESSWS",
  "settings": {
    "clients": [
      {
        "id": "${uuid}",
        "email": "${domain}_VLESS_WS"
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "ws",
    "security": "none",
    "wsSettings": {
      "acceptProxyProtocol": true,
      "path": "/${customPath}ws"
    }
  }
}
]
}
EOF
	fi

#	# VMess_TCP
#	if [[ -n $(echo ${selectCustomInstallType} | grep 2) || "$1" == "all" ]]; then
#		fallbacksList=${fallbacksList}',{"path":"/'${customPath}'tcp","dest":31298,"xver":1}'
#		cat <<EOF >/etc/v2ray-agent/xray/conf/04_VMess_TCP_inbounds.json
#{
#"inbounds":[
#{
#  "port": 31298,
#  "listen": "127.0.0.1",
#  "protocol": "vmess",
#  "tag":"VMessTCP",
#  "settings": {
#    "clients": [
#      {
#        "id": "${uuid}",
#        "alterId": 0,
#        "email": "${domain}_vmess_tcp"
#      }
#    ]
#  },
#  "streamSettings": {
#    "network": "tcp",
#    "security": "none",
#    "tcpSettings": {
#      "acceptProxyProtocol": true,
#      "header": {
#        "type": "http",
#        "request": {
#          "path": [
#            "/${customPath}tcp"
#          ]
#        }
#      }
#    }
#  }
#}
#]
#}
#EOF
#	fi


	# VMess_WS
	if echo "${selectCustomInstallType}" | grep -q 3 || [[ "$1" == "all" ]]; then
		fallbacksList=${fallbacksList}',{"path":"/'${customPath}'vws","dest":31299,"xver":1}'
		cat <<EOF >/etc/v2ray-agent/xray/conf/05_VMess_WS_inbounds.json
{
"inbounds":[
{
  "port": 31299,
  "protocol": "vmess",
  "tag":"VMessWS",
  "settings": {
    "clients": [
      {
        "id": "${uuid}",
        "alterId": 0,
        "add": "${add}",
        "email": "${domain}_vmess_ws"
      }
    ]
  },
  "streamSettings": {
    "network": "ws",
    "security": "none",
    "wsSettings": {
      "acceptProxyProtocol": true,
      "path": "/${customPath}vws"
    }
  }
}
]
}
EOF
	fi

	if echo "${selectCustomInstallType}" | grep -q 5 || [[ "$1" == "all" ]]; then
#		fallbacksList=${fallbacksList}',{"alpn":"h2","dest":31302,"xver":0}'
		cat <<EOF >/etc/v2ray-agent/xray/conf/06_VLESS_gRPC_inbounds.json
{
    "inbounds":[
    {
        "port": 31301,
        "listen": "127.0.0.1",
        "protocol": "vless",
        "tag":"VLESSGRPC",
        "settings": {
            "clients": [
                {
                    "id": "${uuid}",
                    "add": "${add}",
                    "email": "${domain}_VLESS_gRPC"
                }
            ],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "grpc",
            "grpcSettings": {
                "serviceName": "${customPath}grpc"
            }
        }
    }
]
}
EOF
	fi

	# VLESS_TCP
	cat <<EOF >/etc/v2ray-agent/xray/conf/02_VLESS_TCP_inbounds.json
{
"inbounds":[
{
  "port": 443,
  "protocol": "vless",
  "tag":"VLESSTCP",
  "settings": {
    "clients": [
     {
        "id": "${uuid}",
        "add":"${add}",
        "flow":"xtls-rprx-direct",
        "email": "${domain}_VLESS_XTLS/TLS-direct_TCP"
      }
    ],
    "decryption": "none",
    "fallbacks": [
        ${fallbacksList}
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
          "certificateFile": "/etc/v2ray-agent/tls/${domain}.crt",
          "keyFile": "/etc/v2ray-agent/tls/${domain}.key",
          "ocspStapling": 3600,
          "usage":"encipherment"
        }
      ]
    }
  }
}
]
}
EOF
#	if echo "${selectCustomInstallType}" | grep -q 5 || [[ "$1" == "all" ]];then
#		echo >/dev/null
#	elif [[ -f "/etc/v2ray-agent/xray/conf/02_VLESS_TCP_inbounds.json" ]] && echo "${selectCustomInstallType}" | grep -q 4;then
#		# "h2",
#		sed -i '/\"h2\",/d' $(grep "\"h2\"," -rl /etc/v2ray-agent/xray/conf/02_VLESS_TCP_inbounds.json)
#	fi
}
# 定时任务更新tls证书
installCronTLS() {
	echoContent skyBlue "\n进度 $1/${totalProgress} : 添加定时维护证书"
	crontab -l >/etc/v2ray-agent/backup_crontab.cron
	local historyCrontab=$(sed '/v2ray-agent/d;/acme.sh/d' /etc/v2ray-agent/backup_crontab.cron)
	echo "${historyCrontab}" >/etc/v2ray-agent/backup_crontab.cron
	echo "30 1 * * * /bin/bash /etc/v2ray-agent/install.sh RenewTLS >> /etc/v2ray-agent/crontab_tls.log 2>&1" >>/etc/v2ray-agent/backup_crontab.cron
	crontab /etc/v2ray-agent/backup_crontab.cron
	echoContent green "\n ---> 添加定时维护证书成功"
}
# Nginx伪装博客
nginxBlog() {
	echoContent skyBlue "\n进度 $1/${totalProgress} : 添加伪装站点"
	if [[ -d "/usr/share/nginx/html" && -f "/usr/share/nginx/html/check" ]]; then
		echo
		read -r -p "检测到安装伪装站点，是否需要重新安装[y/n]：" nginxBlogInstallStatus
		if [[ "${nginxBlogInstallStatus}" == "y" ]]; then
			rm -rf /usr/share/nginx/html
			randomNum=$((RANDOM%6+1))
			wget -q -P /usr/share/nginx https://raw.githubusercontent.com/mack-a/v2ray-agent/master/fodder/blog/unable/html${randomNum}.zip >/dev/null
			unzip -o /usr/share/nginx/html${randomNum}.zip -d /usr/share/nginx/html >/dev/null
			rm -f /usr/share/nginx/html${randomNum}.zip*
			echoContent green " ---> 添加伪装站点成功"
		fi
	else
		randomNum=$((RANDOM%6+1))
		rm -rf /usr/share/nginx/html
		wget -q -P /usr/share/nginx https://raw.githubusercontent.com/mack-a/v2ray-agent/master/fodder/blog/unable/html${randomNum}.zip >/dev/null
		unzip -o /usr/share/nginx/html${randomNum}.zip -d /usr/share/nginx/html >/dev/null
		rm -f /usr/share/nginx/html${randomNum}.zip*
		echoContent green " ---> 添加伪装站点成功"
	fi

}
# 修改nginx重定向配置
updateRedirectNginxConf() {

	cat <<EOF >/etc/nginx/conf.d/alone.conf
server {
	listen 80;
	listen [::]:80;
	server_name ${domain};
	# shellcheck disable=SC2154
	return 301 https://${domain}$request_uri;
}
server {
		listen 127.0.0.1:31300;
		server_name _;
		return 403;
}
EOF
	if echo "${selectCustomInstallType}" |grep -q 5 || [[ -z "${selectCustomInstallType}" ]]; then
		cat <<EOF >>/etc/nginx/conf.d/alone.conf
server {
	listen 127.0.0.1:31302 http2;
	server_name ${domain};
	root /usr/share/nginx/html;
	location /s/ {
    		add_header Content-Type text/plain;
    		alias /etc/v2ray-agent/subscribe/;
    }
	location /${currentPath}grpc {
		grpc_pass grpc://127.0.0.1:31301;
	}
}
EOF

	else
		cat <<EOF >>/etc/nginx/conf.d/alone.conf
server {
	listen 127.0.0.1:31302 http2;
	server_name ${domain};
	root /usr/share/nginx/html;
	location /s/ {
    		add_header Content-Type text/plain;
    		alias /etc/v2ray-agent/subscribe/;
    }
	location / {
	}
}
EOF
	fi

	cat <<EOF >>/etc/nginx/conf.d/alone.conf
server {
	listen 127.0.0.1:31300;
	server_name ${domain};
	root /usr/share/nginx/html;
	location /s/ {
		add_header Content-Type text/plain;
		alias /etc/v2ray-agent/subscribe/;
	}
	location / {
		add_header Strict-Transport-Security "max-age=15552000; preload" always;
	}
}
EOF

}

# 验证整个服务是否可用
checkGFWStatue() {
	readInstallType
	echoContent skyBlue "\n进度 $1/${totalProgress} : 验证服务启动状态"
	if [[ "${coreInstallType}" == "1" ]] && [[ -n $(pgrep -f xray/xray) ]]; then
		echoContent green " ---> 服务启动成功"
	elif [[ "${coreInstallType}" == "2" || "${coreInstallType}" == "3" ]] && [[ -n $(pgrep -f v2ray/v2ray) ]]; then
		echoContent green " ---> 服务启动成功"
	else
		echoContent red " ---> 服务启动失败，请检查终端是否有日志打印"
		exit 0
	fi

}
# 账号
showAccounts() {
	readInstallType
	readConfigHostPathUUID
	readInstallProtocolType
	echoContent skyBlue "\n进度 $1/${totalProgress} : 账号"
	local show
	# VLESS TCP
	if [[ -n "${configPath}" ]]; then
		show=1
		if echo "${currentInstallProtocolType}" | grep -q 0 || [[ -z "${currentInstallProtocolType}" ]]; then
			echoContent skyBlue "===================== VLESS TCP TLS/XTLS-direct/XTLS-splice ======================\n"
			# cat ${configPath}02_VLESS_TCP_inbounds.json | jq .inbounds[0].settings.clients | jq -c '.[]'
			jq .inbounds[0].settings.clients ${configPath}02_VLESS_TCP_inbounds.json | jq -c '.[]' | while read -r user; do
				echoContent skyBlue "\n ---> 帐号：$(echo "${user}" | jq -r .email )_$(echo "${user}" | jq -r .id)"
				echo
				defaultBase64Code vlesstcp $(echo "${user}" | jq .email) $(echo "${user}" | jq .id) "${currentHost}:${currentPort}" ${currentHost}
			done
		fi

		# VLESS WS
		if echo ${currentInstallProtocolType} | grep -q 1 || [[ -z "${currentInstallProtocolType}" ]]; then
			echoContent skyBlue "\n================================ VLESS WS TLS CDN ================================\n"

			# cat ${configPath}03_VLESS_WS_inbounds.json | jq .inbounds[0].settings.clients | jq -c '.[]'
			jq .inbounds[0].settings.clients ${configPath}03_VLESS_WS_inbounds.json | jq -c '.[]' | while read -r user; do
				echoContent skyBlue "\n ---> 帐号：$(echo "${user}" | jq -r .email )_$(echo "${user}" | jq -r .id)"
				echo
				local path="${currentPath}ws"
				if [[ ${coreInstallType} == "1" ]]; then
					echoContent yellow "Xray的0-RTT path后面会有?ed=2048，不兼容以v2ray为核心的客户端，请手动删除?ed=2048后使用\n"
					path="${currentPath}ws?ed=2048"
				fi
				defaultBase64Code vlessws $(echo "${user}" | jq .email) $(echo "${user}" | jq .id) "${currentHost}:${currentPort}" ${path} ${currentAdd}
			done
		fi

		# VMess TCP
		if echo ${currentInstallProtocolType} | grep -q 2 || [[ -z "${currentInstallProtocolType}" ]]; then
			echoContent skyBlue "\n================================= VMess TCP TLS  =================================\n"

			# cat ${configPath}04_VMess_TCP_inbounds.json | jq .inbounds[0].settings.clients | jq -c '.[]'
			jq .inbounds[0].settings.clients ${configPath}04_VMess_TCP_inbounds.json | jq -c '.[]' | while read -r user; do
				echoContent skyBlue "\n ---> 帐号：$(echo "${user}" | jq -r .email )_$(echo "${user}" | jq -r .id)"
				echo
				defaultBase64Code vmesstcp $(echo "${user}" | jq .email) $(echo "${user}" | jq .id) "${currentHost}:${currentPort}" "${currentPath}tcp" "${currentHost}"
			done
		fi

		# VMess WS
		if echo ${currentInstallProtocolType} | grep -q 3 || [[ -z "${currentInstallProtocolType}" ]]; then
			echoContent skyBlue "\n================================ VMess WS TLS CDN ================================\n"
			local path="${currentPath}vws"
			if [[ ${coreInstallType} == "1" ]]; then
				path="${currentPath}vws?ed=2048"
			fi
			jq .inbounds[0].settings.clients ${configPath}05_VMess_WS_inbounds.json | jq -c '.[]' | while read -r user; do
				echoContent skyBlue "\n ---> 帐号：$(echo "${user}" | jq -r .email )_$(echo "${user}" | jq -r .id)"
				echo
				defaultBase64Code vmessws $(echo "${user}" | jq .email) $(echo "${user}" | jq .id) "${currentHost}:${currentPort}" ${path} ${currentAdd}
			done
		fi

		# VLESS grpc
		if echo ${currentInstallProtocolType} | grep -q 5 || [[ -z "${currentInstallProtocolType}" ]]; then
			echoContent skyBlue "\n=============================== VLESS gRPC TLS CDN ===============================\n"
			local serviceName=$(jq -r .inbounds[0].streamSettings.grpcSettings.serviceName ${configPath}06_VLESS_gRPC_inbounds.json)
			jq .inbounds[0].settings.clients ${configPath}06_VLESS_gRPC_inbounds.json | jq -c '.[]' | while read -r user; do
				echoContent skyBlue "\n ---> 帐号：$(echo "${user}" | jq -r .email )_$(echo "${user}" | jq -r .id)"
				echo
				defaultBase64Code vlessgrpc $(echo "${user}" | jq .email) $(echo "${user}" | jq .id) "${currentHost}:${currentPort}" ${serviceName} ${currentAdd}
			done
		fi
	fi

	# trojan tcp
	if echo ${currentInstallProtocolType} | grep -q 4 || [[ -z "${currentInstallProtocolType}" ]]; then
		echoContent skyBlue "\n==================================  Trojan TLS  ==================================\n"
		jq .inbounds[0].settings.clients ${configPath}04_trojan_TCP_inbounds.json | jq -c '.[]' | while read -r user; do
			echoContent skyBlue "\n ---> 帐号：$(echo "${user}" | jq -r .email )_$(echo "${user}" | jq -r .password)"
			echo
			defaultBase64Code trojan trojan $(echo "${user}" | jq -r .password) ${currentHost}
		done
	fi


#	# trojan-go
#	if [[ -d "/etc/v2ray-agent/" ]] && [[ -d "/etc/v2ray-agent/trojan/" ]] && [[ -f "/etc/v2ray-agent/trojan/config_full.json" ]]; then
#		show=1
#		# local trojanUUID=`cat /etc/v2ray-agent/trojan/config_full.json |jq .password[0]|awk -F '["]' '{print $2}'`
#		local trojanGoPath
#		trojanGoPath=$(jq -r .websocket.path /etc/v2ray-agent/trojan/config_full.json)
#		local trojanGoAdd
#		trojanGoAdd=$(jq .websocket.add /etc/v2ray-agent/trojan/config_full.json | awk -F '["]' '{print $2}')
#		echoContent skyBlue "\n==================================  Trojan TLS  ==================================\n"
#		# cat /etc/v2ray-agent/trojan/config_full.json | jq .password
#		jq -r -c '.password[]' /etc/v2ray-agent/trojan/config_full.json | while read -r user; do
#			trojanUUID=${user}
#			if [[ -n "${trojanUUID}" ]]; then
#				echoContent skyBlue " ---> 帐号：${currentHost}_trojan_${trojanUUID}\n"
#				echo
#				defaultBase64Code trojan trojan ${trojanUUID} ${currentHost}
#			fi
#		done
#
#		echoContent skyBlue "\n================================  Trojan WS TLS   ================================\n"
#		if [[ -z ${trojanGoAdd} ]]; then
#			trojanGoAdd=${currentHost}
#		fi
#
#		jq -r -c '.password[]' /etc/v2ray-agent/trojan/config_full.json | while read -r user; do
#			trojanUUID=${user}
#			if [[ -n "${trojanUUID}" ]]; then
#				echoContent skyBlue " ---> 帐号：${trojanGoAdd}_trojan_ws_${trojanUUID}"
#				echo
#				defaultBase64Code trojangows trojan ${trojanUUID} ${currentHost} ${trojanGoPath} ${trojanGoAdd}
#			fi
#
#		done
#	fi

	if [[ -z ${show} ]]; then
		echoContent red " ---> 未安装"
	fi
}

# xray-core 安装
xrayCoreInstall() {
	cleanUp v2rayClean
	selectCustomInstallType=
	totalProgress=17
	installTools 2
	# 申请tls
	initTLSNginxConfig 3
	installTLS 4
	handleNginx stop
	initNginxConfig 5
	randomPathFunction 6
	# 安装Xray
	handleV2Ray stop
	installXray 7
	installXrayService 8
#	installTrojanGo 9
#	installTrojanService 10
	customCDNIP 11
	initXrayConfig all 12
	cleanUp v2rayDel
#	initTrojanGoConfig 13
	installCronTLS 14
	nginxBlog 15
	updateRedirectNginxConf
	handleXray stop
	sleep 2
	handleXray start

	handleNginx start
#	handleTrojanGo stop
#	sleep 1
#	handleTrojanGo start
	# 生成账号
	checkGFWStatue 16
	showAccounts 17
}

function InstallV2rayAgent {
	# https://github.com/mack-a/v2ray-agent
	# Latest Version
	# wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
	# Stable-v2.4.16
	# wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/stable_v2.4.16/install.sh" && chmod 700 /root/install.sh && /root/install.sh
	print_info "Install v2ray-agent "
	wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh
	judge "安装 v2ray agent "

}
#-----------------------------------------------------------------------------#
# 主菜单
function menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=============================================================="
	echoContent green "SmartTool：v0.056"
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "初始化服务器、安装Docker、执行容器"
	echoContent green "当前系统Linux版本 : \c" 
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
	echoContent yellow "20.git init | 21.git clone | 22.git pull | 23.git push"
	echoContent skyBlue "-------------------------容器相关-----------------------------"
	echoContent yellow "30.One-key"
	echoContent yellow "31.docker-compose up"
	echoContent yellow "32.docker-compose down"
	echoContent yellow "33.docker status"
	echoContent skyBlue "-------------------------证书管理-----------------------------"
	echoContent yellow "41.generate CA | 42.show CA | 43.renew CA"	
	echoContent skyBlue "-------------------------科学上网-----------------------------"
	echoContent yellow "50.安装 v2ray-agent"	
	echoContent yellow "51.安装 BBR"
	echoContent skyBlue "-------------------------脚本管理-----------------------------"
	echoContent yellow "00.更新脚本"
	echoContent yellow "96.show IP"	
	echoContent yellow "97.check system"
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
	20)
		git_init
		;;
	21)
		git_clone_tool_box
		;;
	22)
		github_pull
		;;
	23)
		github_push
		;;
	30)
		shutdown_docker_compose
		github_pull
		github_push
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
	41)
		generate_ca
		;;
	42)
		checkTLStatus "${domain}"
		;;
	43)
		renewalTLS
		;;
	50)
		InstallV2rayAgent
		;;
	51)
		install_bbr
		;;
	96)
		show_ip
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

cleanScreen
initVar $1
#readInstallType
#readInstallProtocolType
#readConfigHostPathUUID
menu "$@"

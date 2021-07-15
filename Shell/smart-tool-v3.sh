#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-25 [Add new functions] - Stop/Start docker-compose
# 2021-July-09 [v3] - Remove non used functions
# 2021-July-12 [logserver] - leverage logserver
#-----------------------------------------------------------------------------#
#================== RHEL 7/8 | CentOS 7/8 | Rocky Linux 8 ====================#
#-----------------------------------------------------------------------------#
# 初始化全局变量
export LANG=en_US.UTF-8
function initVar() {
	# default Host
	defaultHost="k8s-node.cf"
	# default UUID
	defaultUUID="d8206743-b292-43d1-8200-5606238a5abb"
	
	# 随机路径
	customPath="rdxyzukwofngusfpmheud"

	#定义变量
	# WORKDIR="/root/git/toolbox/Docker/docker-compose/${currentHost}/"
	SmartToolDir="/root/git/toolbox/Shell"
	# WORKDIR="/etc/fuckGFW/docker/${currentHost}/"
	# LOGDIR="/root/git/logserver/${currentHost}/"
	GITHUB_REPO_TOOLBOX="/root/git/toolbox/"
	GITHUB_REPO_LOGSERVER="/root/git/logserver/"
	EMAIL="fred.zhong@outlook.com"
	myDate=date
	fallbacksList=

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
	Start="${Yellow}[Start开始]${Font}"
	Info="${Magenta}[Info信息]${Font}"
	OK="${Green}[OK正常]${Font}"
	Error="${Red}[ERROR错误]${Font}"
	DONE="${Green}[Done完成]${Font}"
	
	installType='yum -y install'
	removeType='yum -y remove'
	upgrade="yum -y update"
	echoType='echo -e'

	# current Domain
	currentHost=
	# UUID
	currentUUID=
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

	# centos version
	centosVersion=
	# pingIPv6 pingIPv4
	# pingIPv4=
	pingIPv6=
	# 集成更新证书逻辑不再使用单独的脚本--RenewTLS
	renewTLS=$1

	currentIP=$(curl -s https://ipinfo.io/ip)

	if [[ -f "$HOME/.currentUUID" ]]; then
		currentUUID=$(cat $HOME/.currentUUID)
	else
		currentUUID=${defaultUUID}
	fi
}
#-----------------------------------------------------------------------------#
#打印Start
function print_start() {
	echo -e "${Start} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印Info
function print_info() {
	echo -e "${Info} ${Blue}  $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印OK
function print_ok() {
	echo -e "${OK} ${Blue} $1 ${Font}"
}
#-----------------------------------------------------------------------------#
#打印Done
function print_done() {
	echo -e "${DONE} ${Blue}  $1 ${Font}"
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
	print_start "安装 wget lsof tar unzip curl socat nmap bind-utils jq "
	print_info "安装进行中ing "	
	yum -y install wget lsof tar unzip curl socat nmap bind-utils jq >/dev/null 2>&1
	#  install dig and nslookup --> bind-utils
	judge "安装 wget lsof tar unzip curl socat nmap bind-utils jq "
}
#-----------------------------------------------------------------------------#
# Install acme.sh
function install_acme () {
	print_start "Install acme.sh "
	print_info "安装进行中ing "
	sudo curl -s https://get.acme.sh | sh -s email=$EMAIL >/dev/null 2>&1
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
                    automake autoconf libtool make >/dev/null 2>&1
	print_info "安装进行中ing "
	judge "Install Prerequisites for Python3 "

	print_start "Install bpytop "
	sudo pip3 install bpytop --upgrade >/dev/null 2>&1
	print_info "安装进行中ing "
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
	sleep 0.5
	print_info "安装进行中ing "
	sudo yum -y install webmin >/dev/null 2>&1
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
					docker-engine >/dev/null 2>&1
	judge "1/3 Uninstall old versions of Docker CE "
	print_info "安装进行中ing "
	sudo yum -y install yum-utils >/dev/null 2>&1
	sudo yum-config-manager \
			--add-repo \
			https://download.docker.com/linux/centos/docker-ce.repo  >/dev/null 2>&1
	judge "2/3 Set up the repository for Docker "
	print_info "安装进行中ing "
	sudo yum -y install docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
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
	sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1
	sudo chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose >/dev/null 2>&1
	docker-compose --version >/dev/null 2>&1
	print_info "安装进行中ing "
	judge "Install docker compose "
}
#-----------------------------------------------------------------------------#
# Install Git
# https://git-scm.com
function install_git () {
	print_start "Install Git "
	print_info "安装进行中ing "
	sudo yum -y install git >/dev/null 2>&1
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
	if [[ -d "$HOME/git/" ]];then
		if [[ -d "$HOME/git/toolbox" ]];then
			echoContent yellow "toolbox文件夹已存在，无需重新clone！"
		else
			cd  $HOME/git/
			git clone git@github.com:linfengzhong/toolbox.git
			judge "Git clone ToolBox "

			echoContent green "同步下载 smart-tool-v3.sh 到根目录"
			#cp -pf $HOME/git/toolbox/Docker/docker-compose/$currentHost/smart-tool-v3.sh $HOME
			cp -pf ${SmartToolDir}/smart-tool-v3.sh $HOME
			chmod 700 $HOME/smart-tool-v3.sh
			aliasInstall
		fi
	else
		echoContent yellow "请先初始化Git！"
		exit 0
	fi
}
#-----------------------------------------------------------------------------#
# 同步下载Git文件夹
function github_pull_toolbox () {
	echoContent yellow " ---> ToolBox"
	print_start "下载 -> Local ToolBox Repo "
	cd $GITHUB_REPO_TOOLBOX
	sudo git pull
	judge "下载 -> Local ToolBox Repo "

	echoContent green "同步下载 smart-tool-v3.sh 到根目录"
	#cp -pf $HOME/git/toolbox/Docker/docker-compose/$currentHost/smart-tool-v3.sh $HOME
	cp -pf ${SmartToolDir}/smart-tool-v3.sh $HOME
	chmod 700 $HOME/smart-tool-v3.sh
	aliasInstall

}
#-----------------------------------------------------------------------------#
# 同步上传Git文件夹
function github_push_toolbox () {
	echoContent yellow " ---> ToolBox"
	print_start "上传ToolBox -> GitHub "
	cd $GITHUB_REPO_TOOLBOX
	sudo git add .
	sudo git commit -m "${myDate} fix"
	sudo git push
	judge "上传ToolBox -> GitHub "
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
	mkdir -p $HOME/git/logserver/$currentHost
	mkdir -p $HOME/git/logserver/$currentHost/nginx
	mkdir -p $HOME/git/logserver/$currentHost/portainer/data
	mkdir -p $HOME/git/logserver/$currentHost/trojan-go
	mkdir -p $HOME/git/logserver/$currentHost/v2ray
	mkdir -p $HOME/git/logserver/$currentHost/xray
	mkdir -p $HOME/git/logserver/$currentHost/prometheus
	mkdir -p $HOME/git/logserver/$currentHost/grafana/
	mkdir -p $HOME/git/logserver/$currentHost/grafana/lib
	chmod 777 -R $HOME/git/logserver/$currentHost/grafana/lib
}
#-----------------------------------------------------------------------------#
# 同步下载Git文件夹
function github_pull_logserver () {
	echoContent yellow " ---> logserver"
	print_start "下载 -> Local logserver Repo "
	cd $GITHUB_REPO_LOGSERVER
	sudo git pull
	chmod 777 -R $HOME/git/logserver/$currentHost/grafana/lib	
	judge "下载 -> Local logserver Repo "
}
#-----------------------------------------------------------------------------#
# 同步上传Git文件夹
function github_push_logserver () {
	echoContent yellow " ---> logserver"
	print_start "上传logserver -> GitHub "
	cd $GITHUB_REPO_LOGSERVER
	sudo git add .
	sudo git commit -m "${myDate} sync_all_config_log_data"
	sudo git push
	judge "上传logserver -> GitHub "
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
	print_start "生成网站证书 "
	print_info "默认域名: $currentHost"	
	show_ip
	local tempDomainName
	if [[ -d "$HOME/.acme.sh/${currentHost}" ]] && [[ -f "$HOME/.acme.sh/${currentHost}/${currentHost}.key" ]] && [[ -f "$HOME/.acme.sh/${currentHost}/${currentHost}.cer" ]]; then
		print_info "证书已经存在，无需重新生成！！！"
	else
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
		print_info "复制证书到xray配置文件夹 "
		cp -pf /etc/fuckGFW/tls/*.* /etc/fuckGFW/xray/${currentHost}/
		installCronTLS
	fi
	judge "生成网站证书 "
}
#-----------------------------------------------------------------------------#
# 更新证书
function renewalTLS() {
	print_start "更新证书 "
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

		print_info "证书检查日期:$(date "+%F %H:%M:%S")"
		print_info "证书生成日期:$(date -d @"${modifyTime}" +"%F %H:%M:%S")"
		print_info "证书生成天数:${days}"
		print_info "证书剩余天数:"${tlsStatus}
		print_info "证书过期前最后一天自动更新，如更新失败请手动更新"

		if [[ ${remainingDays} -le 1 ]]; then
			print_info " ---> 重新生成证书"
			sh /root/.acme.sh/acme.sh  --issue  -d $currentHost --standalone --force

		else
			print_info " ---> 证书有效"
		fi
	else
		echoContent red " ---> 未安装"
	fi
	judge "更新证书 "
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
	mkdir -p /etc/fuckGFW/prometheus/groups
	mkdir -p /etc/fuckGFW/prometheus/rules
	mkdir -p /etc/fuckGFW/grafana/
	mkdir -p /etc/fuckGFW/webmin/
	mkdir -p /etc/fuckGFW/clash
	mkdir -p /etc/fuckGFW/standalone/trojan-go
#	mkdir -p /etc/systemd/system/
#	mkdir -p /tmp/fuckGFW-tls/

}

#-----------------------------------------------------------------------------#
# Show IP
function show_ip () {
	# local zIP=$(curl -s https://ipinfo.io/ip)
	print_info "服务器外部 IP: ${currentIP} "
}
#-----------------------------------------------------------------------------#
# Generate UUID
function generate_uuid () {
	local zUUID=$(cat /proc/sys/kernel/random/uuid)
	print_info "随机生成 UUID: $zUUID "
}
#-----------------------------------------------------------------------------#
# Set timezone
function set_timezone () {
	print_start "设置时区： Asia/Shanghai "
	timedatectl set-timezone Asia/Shanghai
	echoContent yellow "[当前时间]  \c"
	sudo date
	judge "设置时区： Asia/Shanghai "
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
    listen 443;
    server_name ${currentHost};
    root /usr/share/nginx/html;

    location / {
        add_header Strict-Transport-Security "max-age=63072000" always;
    }

    location /portainer/ {
        proxy_pass http://portainer:9000/;
    }
    
	location /grafana/ {
        proxy_pass http://grafana:3000/;
    }
}
EOF
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

	fallbacksList='{"dest":"trojan-go:443","xver":0}'
	fallbacksList=${fallbacksList}',{"path":"/'${customPath}'vlessws","dest":37211,"xver":1}'
	fallbacksList=${fallbacksList}',{"path":"/'${customPath}'vmessws","dest":37212,"xver":1}'
	fallbacksList=${fallbacksList}',{"path":"/'${customPath}'v2rayws","dest":"v2ray:443","xver":1}'

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
      "port": 37211,
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
          "path": "/${customPath}vlessws"
        }
      }
    },
    {
      "port": 37212,
      "protocol": "vmess",
      "tag":"VMessWS",
      "settings": {
        "clients": [
          {
            "id": "${currentUUID}",
            "alterId": 64,
            "add": "${currentHost}",
            "email": "${currentHost}_vmess_ws"
          }
        ]
       },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/${customPath}vmessws"
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
	print_info "复制证书到xray配置文件夹 "
	cp -pf /etc/fuckGFW/tls/*.* /etc/fuckGFW/xray/${currentHost}/
	judge "生成 xray 配置文件 "
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
    "local_port": 443,
    "remote_addr": "nginx",
    "remote_port": 443,
    "disable_http_check":true,
    "log_level":0,
    "log_file":"/etc/trojan-go/error.log",
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
        "path": "/${customPath}trojanws",
        "host": "${currentHost}",
        "add": "${currentHost}"
    },
    "router": {
        "enabled": false
    }
}
EOF
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
      "protocol": "vmess",
      "tag":"VMessWS",
      "settings": {
        "clients": [
			{
				"id": "${currentUUID}",
				"alterId": 64,
				"level": 0,
				"email": "${currentHost}_vmess_ws"
			}
          ],
        "fallbacks":[
          {"dest":"nginx:443"}
          ]
        },
        "streamSettings": {
			"network": "ws",
			"security": "auto",
			"wsSettings": {
			"acceptProxyProtocol": true,
			"path": "/${customPath}v2rayws"
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
	judge "生成 v2ray 配置文件 "
}
#-----------------------------------------------------------------------------#
# 生成 prometheus 配置文件
function generate_prometheus_conf {
	# https://www.v2fly.org/config/overview.html
	# /etc/fuckGFW/v2ray
	print_start "生成 prometheus 配置文件 "
	print_info "/etc/fuckGFW/prometheus/prometheus.yml"
	cat <<EOF >/etc/fuckGFW/prometheus/prometheus.yml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
# alerting:
#  alertmanagers:
#  - static_configs:
#    - targets: ['alertmanager:9090']
  #  - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=job_name` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  - job_name: "docker"
    static_configs:
    - targets: ['cadvisor:8080']

  - job_name: "linux"
    static_configs:
    - targets: ['35.185.165.176:9100','34.80.73.27:9100','35.221.170.54:9100']
EOF
	judge "生成 prometheus 配置文件 "
}
#-----------------------------------------------------------------------------#
# 生成 grafana.ini 配置文件
function generate_grafana_ini {
	print_start "生成 grafana.ini 配置文件 "
	print_info "/etc/fuckGFW/grafana/grafana.ini"
	cat <<EOF >/etc/fuckGFW/grafana/grafana.ini
##################### Grafana Configuration Example #####################
#
# Everything has defaults so you only need to uncomment things you want to
# change

# possible values : production, development
;app_mode = production

# instance name, defaults to HOSTNAME environment variable value or hostname if HOSTNAME var is empty
;instance_name = ${HOSTNAME}

#################################### Paths ####################################
[paths]
# Path to where grafana can store temp files, sessions, and the sqlite3 db (if that is used)
;data = /var/lib/grafana

# Temporary files in `data` directory older than given duration will be removed
;temp_data_lifetime = 24h

# Directory where grafana can store logs
;logs = /var/log/grafana

# Directory where grafana will automatically scan and look for plugins
;plugins = /var/lib/grafana/plugins

# folder that contains provisioning config files that grafana will apply on startup and while running.
;provisioning = conf/provisioning

#################################### Server ####################################
[server]
# Protocol (http, https, h2, socket)
;protocol = http

# The ip address to bind to, empty will bind to all interfaces
;http_addr =

# The http port  to use
;http_port = 3000

# The public facing domain name used to access grafana from a browser
;domain = localhost

# Redirect to correct domain if host header does not match domain
# Prevents DNS rebinding attacks
;enforce_domain = false

# The full public facing url you use in browser, used for redirects and emails
# If you use reverse proxy and sub path specify full url (with sub path)
;root_url = %(protocol)s://%(domain)s:%(http_port)s/

# Serve Grafana from subpath specified in `root_url` setting. By default it is set to `false` for compatibility reasons.
;serve_from_sub_path = false

# Log web requests
;router_logging = false

# the path relative working path
;static_root_path = public

# enable gzip
;enable_gzip = false

# https certs & key file
;cert_file =
;cert_key =

# Unix socket path
;socket =

# CDN Url
;cdn_url =

# Sets the maximum time using a duration format (5s/5m/5ms) before timing out read of an incoming request and closing idle connections.
# `0` means there is no timeout for reading the request.
;read_timeout = 0

#################################### Database ####################################
[database]
# You can configure the database connection by specifying type, host, name, user and password
# as separate properties or as on string using the url properties.

# Either "mysql", "postgres" or "sqlite3", it's your choice
;type = sqlite3
;host = 127.0.0.1:3306
;name = grafana
;user = root
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
;password =

# Use either URL or the previous fields to configure the database
# Example: mysql://user:secret@host:port/database
;url =

# For "postgres" only, either "disable", "require" or "verify-full"
;ssl_mode = disable

# Database drivers may support different transaction isolation levels.
# Currently, only "mysql" driver supports isolation levels.
# If the value is empty - driver's default isolation level is applied.
# For "mysql" use "READ-UNCOMMITTED", "READ-COMMITTED", "REPEATABLE-READ" or "SERIALIZABLE".
;isolation_level =

;ca_cert_path =
;client_key_path =
;client_cert_path =
;server_cert_name =

# For "sqlite3" only, path relative to data_path setting
;path = grafana.db

# Max idle conn setting default is 2
;max_idle_conn = 2

# Max conn setting default is 0 (mean not set)
;max_open_conn =

# Connection Max Lifetime default is 14400 (means 14400 seconds or 4 hours)
;conn_max_lifetime = 14400

# Set to true to log the sql calls and execution times.
;log_queries =

# For "sqlite3" only. cache mode setting used for connecting to the database. (private, shared)
;cache_mode = private

################################### Data sources #########################
[datasources]
# Upper limit of data sources that Grafana will return. This limit is a temporary configuration and it will be deprecated when pagination will be introduced on the list data sources API.
;datasource_limit = 5000

#################################### Cache server #############################
[remote_cache]
# Either "redis", "memcached" or "database" default is "database"
;type = database

# cache connectionstring options
# database: will use Grafana primary database.
# redis: config like redis server e.g. `addr=127.0.0.1:6379,pool_size=100,db=0,ssl=false`. Only addr is required. ssl may be 'true', 'false', or 'insecure'.
# memcache: 127.0.0.1:11211
;connstr =

#################################### Data proxy ###########################
[dataproxy]

# This enables data proxy logging, default is false
;logging = false

# How long the data proxy waits before timing out, default is 30 seconds.
# This setting also applies to core backend HTTP data sources where query requests use an HTTP client with timeout set.
;timeout = 30

# How many seconds the data proxy waits before sending a keepalive probe request.
;keep_alive_seconds = 30

# How many seconds the data proxy waits for a successful TLS Handshake before timing out.
;tls_handshake_timeout_seconds = 10

# How many seconds the data proxy will wait for a server's first response headers after
# fully writing the request headers if the request has an "Expect: 100-continue"
# header. A value of 0 will result in the body being sent immediately, without
# waiting for the server to approve.
;expect_continue_timeout_seconds = 1

# The maximum number of idle connections that Grafana will keep alive.
;max_idle_connections = 100

# How many seconds the data proxy keeps an idle connection open before timing out.
;idle_conn_timeout_seconds = 90

# If enabled and user is not anonymous, data proxy will add X-Grafana-User header with username into the request, default is false.
;send_user_header = false

#################################### Analytics ####################################
[analytics]
# Server reporting, sends usage counters to stats.grafana.org every 24 hours.
# No ip addresses are being tracked, only simple counters to track
# running instances, dashboard and error counts. It is very helpful to us.
# Change this option to false to disable reporting.
;reporting_enabled = true

# The name of the distributor of the Grafana instance. Ex hosted-grafana, grafana-labs
;reporting_distributor = grafana-labs

# Set to false to disable all checks to https://grafana.net
# for new versions (grafana itself and plugins), check is used
# in some UI views to notify that grafana or plugin update exists
# This option does not cause any auto updates, nor send any information
# only a GET request to http://grafana.com to get latest versions
;check_for_updates = true

# Google Analytics universal tracking code, only enabled if you specify an id here
;google_analytics_ua_id =

# Google Tag Manager ID, only enabled if you specify an id here
;google_tag_manager_id =

#################################### Security ####################################
[security]
# disable creation of admin user on first start of grafana
;disable_initial_admin_creation = false

# default admin user, created on startup
;admin_user = admin

# default admin password, can be changed before first start of grafana,  or in profile settings
;admin_password = admin

# used for signing
;secret_key = SW2YcwTIb9zpOOhoPsMm

# disable gravatar profile images
;disable_gravatar = false

# data source proxy whitelist (ip_or_domain:port separated by spaces)
;data_source_proxy_whitelist =

# disable protection against brute force login attempts
;disable_brute_force_login_protection = false

# set to true if you host Grafana behind HTTPS. default is false.
;cookie_secure = false

# set cookie SameSite attribute. defaults to `lax`. can be set to "lax", "strict", "none" and "disabled"
;cookie_samesite = lax

# set to true if you want to allow browsers to render Grafana in a <frame>, <iframe>, <embed> or <object>. default is false.
;allow_embedding = false

# Set to true if you want to enable http strict transport security (HSTS) response header.
# This is only sent when HTTPS is enabled in this configuration.
# HSTS tells browsers that the site should only be accessed using HTTPS.
;strict_transport_security = false

# Sets how long a browser should cache HSTS. Only applied if strict_transport_security is enabled.
;strict_transport_security_max_age_seconds = 86400

# Set to true if to enable HSTS preloading option. Only applied if strict_transport_security is enabled.
;strict_transport_security_preload = false

# Set to true if to enable the HSTS includeSubDomains option. Only applied if strict_transport_security is enabled.
;strict_transport_security_subdomains = false

# Set to true to enable the X-Content-Type-Options response header.
# The X-Content-Type-Options response HTTP header is a marker used by the server to indicate that the MIME types advertised
# in the Content-Type headers should not be changed and be followed.
;x_content_type_options = true

# Set to true to enable the X-XSS-Protection header, which tells browsers to stop pages from loading
# when they detect reflected cross-site scripting (XSS) attacks.
;x_xss_protection = true

# Enable adding the Content-Security-Policy header to your requests.
# CSP allows to control resources the user agent is allowed to load and helps prevent XSS attacks.
;content_security_policy = false

# Set Content Security Policy template used when adding the Content-Security-Policy header to your requests.
# $NONCE in the template includes a random nonce.
;content_security_policy_template = """script-src 'unsafe-eval' 'strict-dynamic' $NONCE;object-src 'none';font-src 'self';style-src 'self' 'unsafe-inline';img-src 'self' data:;base-uri 'self';connect-src 'self' grafana.com;manifest-src 'self';media-src 'none';form-action 'self';"""

#################################### Snapshots ###########################
[snapshots]
# snapshot sharing options
;external_enabled = true
;external_snapshot_url = https://snapshots-origin.raintank.io
;external_snapshot_name = Publish to snapshot.raintank.io

# Set to true to enable this Grafana instance act as an external snapshot server and allow unauthenticated requests for
# creating and deleting snapshots.
;public_mode = false

# remove expired snapshot
;snapshot_remove_expired = true

#################################### Dashboards History ##################
[dashboards]
# Number dashboard versions to keep (per dashboard). Default: 20, Minimum: 1
;versions_to_keep = 20

# Minimum dashboard refresh interval. When set, this will restrict users to set the refresh interval of a dashboard lower than given interval. Per default this is 5 seconds.
# The interval string is a possibly signed sequence of decimal numbers, followed by a unit suffix (ms, s, m, h, d), e.g. 30s or 1m.
;min_refresh_interval = 5s

# Path to the default home dashboard. If this value is empty, then Grafana uses StaticRootPath + "dashboards/home.json"
;default_home_dashboard_path =

#################################### Users ###############################
[users]
# disable user signup / registration
;allow_sign_up = true

# Allow non admin users to create organizations
;allow_org_create = true

# Set to true to automatically assign new users to the default organization (id 1)
;auto_assign_org = true

# Set this value to automatically add new users to the provided organization (if auto_assign_org above is set to true)
;auto_assign_org_id = 1

# Default role new users will be automatically assigned (if disabled above is set to true)
;auto_assign_org_role = Viewer

# Require email validation before sign up completes
;verify_email_enabled = false

# Background text for the user field on the login page
;login_hint = email or username
;password_hint = password

# Default UI theme ("dark" or "light")
;default_theme = dark

# Path to a custom home page. Users are only redirected to this if the default home dashboard is used. It should match a frontend route and contain a leading slash.
; home_page =

# External user management, these options affect the organization users view
;external_manage_link_url =
;external_manage_link_name =
;external_manage_info =

# Viewers can edit/inspect dashboard settings in the browser. But not save the dashboard.
;viewers_can_edit = false

# Editors can administrate dashboard, folders and teams they create
;editors_can_admin = false

# The duration in time a user invitation remains valid before expiring. This setting should be expressed as a duration. Examples: 6h (hours), 2d (days), 1w (week). Default is 24h (24 hours). The minimum supported duration is 15m (15 minutes).
;user_invite_max_lifetime_duration = 24h

# Enter a comma-separated list of users login to hide them in the Grafana UI. These users are shown to Grafana admins and themselves.
; hidden_users =

[auth]
# Login cookie name
;login_cookie_name = grafana_session

# The maximum lifetime (duration) an authenticated user can be inactive before being required to login at next visit. Default is 7 days (7d). This setting should be expressed as a duration, e.g. 5m (minutes), 6h (hours), 10d (days), 2w (weeks), 1M (month). The lifetime resets at each successful token rotation.
;login_maximum_inactive_lifetime_duration =

# The maximum lifetime (duration) an authenticated user can be logged in since login time before being required to login. Default is 30 days (30d). This setting should be expressed as a duration, e.g. 5m (minutes), 6h (hours), 10d (days), 2w (weeks), 1M (month).
;login_maximum_lifetime_duration =

# How often should auth tokens be rotated for authenticated users when being active. The default is each 10 minutes.
;token_rotation_interval_minutes = 10

# Set to true to disable (hide) the login form, useful if you use OAuth, defaults to false
;disable_login_form = false

# Set to true to disable the signout link in the side menu. useful if you use auth.proxy, defaults to false
;disable_signout_menu = false

# URL to redirect the user to after sign out
;signout_redirect_url =

# Set to true to attempt login with OAuth automatically, skipping the login screen.
# This setting is ignored if multiple OAuth providers are configured.
;oauth_auto_login = false

# OAuth state max age cookie duration in seconds. Defaults to 600 seconds.
;oauth_state_cookie_max_age = 600

# limit of api_key seconds to live before expiration
;api_key_max_seconds_to_live = -1

# Set to true to enable SigV4 authentication option for HTTP-based datasources.
;sigv4_auth_enabled = false

#################################### Anonymous Auth ######################
[auth.anonymous]
# enable anonymous access
;enabled = false

# specify organization name that should be used for unauthenticated users
;org_name = Main Org.

# specify role for unauthenticated users
;org_role = Viewer

# mask the Grafana version number for unauthenticated users
;hide_version = false

#################################### GitHub Auth ##########################
[auth.github]
;enabled = false
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = user:email,read:org
;auth_url = https://github.com/login/oauth/authorize
;token_url = https://github.com/login/oauth/access_token
;api_url = https://api.github.com/user
;allowed_domains =
;team_ids =
;allowed_organizations =

#################################### GitLab Auth #########################
[auth.gitlab]
;enabled = false
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = api
;auth_url = https://gitlab.com/oauth/authorize
;token_url = https://gitlab.com/oauth/token
;api_url = https://gitlab.com/api/v4
;allowed_domains =
;allowed_groups =

#################################### Google Auth ##########################
[auth.google]
;enabled = false
;allow_sign_up = true
;client_id = some_client_id
;client_secret = some_client_secret
;scopes = https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email
;auth_url = https://accounts.google.com/o/oauth2/auth
;token_url = https://accounts.google.com/o/oauth2/token
;api_url = https://www.googleapis.com/oauth2/v1/userinfo
;allowed_domains =
;hosted_domain =

#################################### Grafana.com Auth ####################
[auth.grafana_com]
;enabled = false
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = user:email
;allowed_organizations =

#################################### Azure AD OAuth #######################
[auth.azuread]
;name = Azure AD
;enabled = false
;allow_sign_up = true
;client_id = some_client_id
;client_secret = some_client_secret
;scopes = openid email profile
;auth_url = https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/authorize
;token_url = https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token
;allowed_domains =
;allowed_groups =

#################################### Okta OAuth #######################
[auth.okta]
;name = Okta
;enabled = false
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = openid profile email groups
;auth_url = https://<tenant-id>.okta.com/oauth2/v1/authorize
;token_url = https://<tenant-id>.okta.com/oauth2/v1/token
;api_url = https://<tenant-id>.okta.com/oauth2/v1/userinfo
;allowed_domains =
;allowed_groups =
;role_attribute_path =

#################################### Generic OAuth ##########################
[auth.generic_oauth]
;enabled = false
;name = OAuth
;allow_sign_up = true
;client_id = some_id
;client_secret = some_secret
;scopes = user:email,read:org
;email_attribute_name = email:primary
;email_attribute_path =
;login_attribute_path =
;name_attribute_path =
;id_token_attribute_name =
;auth_url = https://foo.bar/login/oauth/authorize
;token_url = https://foo.bar/login/oauth/access_token
;api_url = https://foo.bar/user
;allowed_domains =
;team_ids =
;allowed_organizations =
;role_attribute_path =
;tls_skip_verify_insecure = false
;tls_client_cert =
;tls_client_key =
;tls_client_ca =

#################################### Basic Auth ##########################
[auth.basic]
;enabled = true

#################################### Auth Proxy ##########################
[auth.proxy]
;enabled = false
;header_name = X-WEBAUTH-USER
;header_property = username
;auto_sign_up = true
;sync_ttl = 60
;whitelist = 192.168.1.1, 192.168.2.1
;headers = Email:X-User-Email, Name:X-User-Name
# Read the auth proxy docs for details on what the setting below enables
;enable_login_token = false

#################################### Auth LDAP ##########################
[auth.ldap]
;enabled = false
;config_file = /etc/grafana/ldap.toml
;allow_sign_up = true

# LDAP background sync (Enterprise only)
# At 1 am every day
;sync_cron = "0 0 1 * * *"
;active_sync_enabled = true

#################################### AWS ###########################
[aws]
# Enter a comma-separated list of allowed AWS authentication providers. 
# Options are: default (AWS SDK Default), keys (Access && secret key), credentials (Credentials field), ec2_iam_role (EC2 IAM Role)
; allowed_auth_providers = default,keys,credentials

# Allow AWS users to assume a role using temporary security credentials. 
# If true, assume role will be enabled for all AWS authentication providers that are specified in aws_auth_providers
; assume_role_enabled = true

#################################### SMTP / Emailing ##########################
[smtp]
;enabled = false
;host = localhost:25
;user =
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
;password =
;cert_file =
;key_file =
;skip_verify = false
;from_address = admin@grafana.localhost
;from_name = Grafana
# EHLO identity in SMTP dialog (defaults to instance_name)
;ehlo_identity = dashboard.example.com
# SMTP startTLS policy (defaults to 'OpportunisticStartTLS')
;startTLS_policy = NoStartTLS

[emails]
;welcome_email_on_sign_up = false
;templates_pattern = emails/*.html

#################################### Logging ##########################
[log]
# Either "console", "file", "syslog". Default is console and  file
# Use space to separate multiple modes, e.g. "console file"
;mode = console file

# Either "debug", "info", "warn", "error", "critical", default is "info"
;level = info

# optional settings to set different levels for specific loggers. Ex filters = sqlstore:debug
;filters =

# For "console" mode only
[log.console]
;level =

# log line format, valid options are text, console and json
;format = console

# For "file" mode only
[log.file]
;level =

# log line format, valid options are text, console and json
;format = text

# This enables automated log rotate(switch of following options), default is true
;log_rotate = true

# Max line number of single file, default is 1000000
;max_lines = 1000000

# Max size shift of single file, default is 28 means 1 << 28, 256MB
;max_size_shift = 28

# Segment log daily, default is true
;daily_rotate = true

# Expired days of log file(delete after max days), default is 7
;max_days = 7

[log.syslog]
;level =

# log line format, valid options are text, console and json
;format = text

# Syslog network type and address. This can be udp, tcp, or unix. If left blank, the default unix endpoints will be used.
;network =
;address =

# Syslog facility. user, daemon and local0 through local7 are valid.
;facility =

# Syslog tag. By default, the process' argv[0] is used.
;tag =

[log.frontend]
# Should Sentry javascript agent be initialized
;enabled = false

# Sentry DSN if you want to send events to Sentry.
;sentry_dsn =

# Custom HTTP endpoint to send events captured by the Sentry agent to. Default will log the events to stdout.
;custom_endpoint = /log

# Rate of events to be reported between 0 (none) and 1 (all), float
;sample_rate = 1.0

# Requests per second limit enforced an extended period, for Grafana backend log ingestion endpoint (/log).
;log_endpoint_requests_per_second_limit = 3

# Max requests accepted per short interval of time for Grafana backend log ingestion endpoint (/log).
;log_endpoint_burst_limit = 15

#################################### Usage Quotas ########################
[quota]
; enabled = false

#### set quotas to -1 to make unlimited. ####
# limit number of users per Org.
; org_user = 10

# limit number of dashboards per Org.
; org_dashboard = 100

# limit number of data_sources per Org.
; org_data_source = 10

# limit number of api_keys per Org.
; org_api_key = 10

# limit number of orgs a user can create.
; user_org = 10

# Global limit of users.
; global_user = -1

# global limit of orgs.
; global_org = -1

# global limit of dashboards
; global_dashboard = -1

# global limit of api_keys
; global_api_key = -1

# global limit on number of logged in users.
; global_session = -1

#################################### Alerting ############################
[alerting]
# Disable alerting engine & UI features
;enabled = true
# Makes it possible to turn off alert rule execution but alerting UI is visible
;execute_alerts = true

# Default setting for new alert rules. Defaults to categorize error and timeouts as alerting. (alerting, keep_state)
;error_or_timeout = alerting

# Default setting for how Grafana handles nodata or null values in alerting. (alerting, no_data, keep_state, ok)
;nodata_or_nullvalues = no_data

# Alert notifications can include images, but rendering many images at the same time can overload the server
# This limit will protect the server from render overloading and make sure notifications are sent out quickly
;concurrent_render_limit = 5


# Default setting for alert calculation timeout. Default value is 30
;evaluation_timeout_seconds = 30

# Default setting for alert notification timeout. Default value is 30
;notification_timeout_seconds = 30

# Default setting for max attempts to sending alert notifications. Default value is 3
;max_attempts = 3

# Makes it possible to enforce a minimal interval between evaluations, to reduce load on the backend
;min_interval_seconds = 1

# Configures for how long alert annotations are stored. Default is 0, which keeps them forever.
# This setting should be expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).
;max_annotation_age =

# Configures max number of alert annotations that Grafana stores. Default value is 0, which keeps all alert annotations.
;max_annotations_to_keep =

#################################### Annotations #########################
[annotations]
# Configures the batch size for the annotation clean-up job. This setting is used for dashboard, API, and alert annotations.
;cleanupjob_batchsize = 100

[annotations.dashboard]
# Dashboard annotations means that annotations are associated with the dashboard they are created on.

# Configures how long dashboard annotations are stored. Default is 0, which keeps them forever.
# This setting should be expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).
;max_age =

# Configures max number of dashboard annotations that Grafana stores. Default value is 0, which keeps all dashboard annotations.
;max_annotations_to_keep =

[annotations.api]
# API annotations means that the annotations have been created using the API without any
# association with a dashboard.

# Configures how long Grafana stores API annotations. Default is 0, which keeps them forever.
# This setting should be expressed as a duration. Examples: 6h (hours), 10d (days), 2w (weeks), 1M (month).
;max_age =

# Configures max number of API annotations that Grafana keeps. Default value is 0, which keeps all API annotations.
;max_annotations_to_keep =

#################################### Explore #############################
[explore]
# Enable the Explore section
;enabled = true

#################################### Internal Grafana Metrics ##########################
# Metrics available at HTTP API Url /metrics
[metrics]
# Disable / Enable internal metrics
;enabled           = true
# Graphite Publish interval
;interval_seconds  = 10
# Disable total stats (stat_totals_*) metrics to be generated
;disable_total_stats = false

#If both are set, basic auth will be required for the metrics endpoint.
; basic_auth_username =
; basic_auth_password =

# Metrics environment info adds dimensions to the `grafana_environment_info` metric, which
# can expose more information about the Grafana instance.
[metrics.environment_info]
#exampleLabel1 = exampleValue1
#exampleLabel2 = exampleValue2

# Send internal metrics to Graphite
[metrics.graphite]
# Enable by setting the address setting (ex localhost:2003)
;address =
;prefix = prod.grafana.%(instance_name)s.

#################################### Grafana.com integration  ##########################
# Url used to import dashboards directly from Grafana.com
[grafana_com]
;url = https://grafana.com

#################################### Distributed tracing ############
[tracing.jaeger]
# Enable by setting the address sending traces to jaeger (ex localhost:6831)
;address = localhost:6831
# Tag that will always be included in when creating new spans. ex (tag1:value1,tag2:value2)
;always_included_tag = tag1:value1
# Type specifies the type of the sampler: const, probabilistic, rateLimiting, or remote
;sampler_type = const
# jaeger samplerconfig param
# for "const" sampler, 0 or 1 for always false/true respectively
# for "probabilistic" sampler, a probability between 0 and 1
# for "rateLimiting" sampler, the number of spans per second
# for "remote" sampler, param is the same as for "probabilistic"
# and indicates the initial sampling rate before the actual one
# is received from the mothership
;sampler_param = 1
# sampling_server_url is the URL of a sampling manager providing a sampling strategy.
;sampling_server_url =
# Whether or not to use Zipkin propagation (x-b3- HTTP headers).
;zipkin_propagation = false
# Setting this to true disables shared RPC spans.
# Not disabling is the most common setting when using Zipkin elsewhere in your infrastructure.
;disable_shared_zipkin_spans = false

#################################### External image storage ##########################
[external_image_storage]
# Used for uploading images to public servers so they can be included in slack/email messages.
# you can choose between (s3, webdav, gcs, azure_blob, local)
;provider =

[external_image_storage.s3]
;endpoint =
;path_style_access =
;bucket =
;region =
;path =
;access_key =
;secret_key =

[external_image_storage.webdav]
;url =
;public_url =
;username =
;password =

[external_image_storage.gcs]
;key_file =
;bucket =
;path =

[external_image_storage.azure_blob]
;account_name =
;account_key =
;container_name =

[external_image_storage.local]
# does not require any configuration

[rendering]
# Options to configure a remote HTTP image rendering service, e.g. using https://github.com/grafana/grafana-image-renderer.
# URL to a remote HTTP image renderer service, e.g. http://localhost:8081/render, will enable Grafana to render panels and dashboards to PNG-images using HTTP requests to an external service.
;server_url =
# If the remote HTTP image renderer service runs on a different server than the Grafana server you may have to configure this to a URL where Grafana is reachable, e.g. http://grafana.domain/.
;callback_url =
# Concurrent render request limit affects when the /render HTTP endpoint is used. Rendering many images at the same time can overload the server,
# which this setting can help protect against by only allowing a certain amount of concurrent requests.
;concurrent_render_request_limit = 30

[panels]
# If set to true Grafana will allow script tags in text panels. Not recommended as it enable XSS vulnerabilities.
;disable_sanitize_html = false

[plugins]
;enable_alpha = false
;app_tls_skip_verify_insecure = false
# Enter a comma-separated list of plugin identifiers to identify plugins that are allowed to be loaded even if they lack a valid signature.
;allow_loading_unsigned_plugins =
;marketplace_url = https://grafana.com/grafana/plugins/

#################################### Grafana Image Renderer Plugin ##########################
[plugin.grafana-image-renderer]
# Instruct headless browser instance to use a default timezone when not provided by Grafana, e.g. when rendering panel image of alert.
# See ICU’s metaZones.txt (https://cs.chromium.org/chromium/src/third_party/icu/source/data/misc/metaZones.txt) for a list of supported
# timezone IDs. Fallbacks to TZ environment variable if not set.
;rendering_timezone =

# Instruct headless browser instance to use a default language when not provided by Grafana, e.g. when rendering panel image of alert.
# Please refer to the HTTP header Accept-Language to understand how to format this value, e.g. 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5'.
;rendering_language =

# Instruct headless browser instance to use a default device scale factor when not provided by Grafana, e.g. when rendering panel image of alert.
# Default is 1. Using a higher value will produce more detailed images (higher DPI), but will require more disk space to store an image.
;rendering_viewport_device_scale_factor =

# Instruct headless browser instance whether to ignore HTTPS errors during navigation. Per default HTTPS errors are not ignored. Due to
# the security risk it's not recommended to ignore HTTPS errors.
;rendering_ignore_https_errors =

# Instruct headless browser instance whether to capture and log verbose information when rendering an image. Default is false and will
# only capture and log error messages. When enabled, debug messages are captured and logged as well.
# For the verbose information to be included in the Grafana server log you have to adjust the rendering log level to debug, configure
# [log].filter = rendering:debug.
;rendering_verbose_logging =

# Instruct headless browser instance whether to output its debug and error messages into running process of remote rendering service.
# Default is false. This can be useful to enable (true) when troubleshooting.
;rendering_dumpio =

# Additional arguments to pass to the headless browser instance. Default is --no-sandbox. The list of Chromium flags can be found
# here (https://peter.sh/experiments/chromium-command-line-switches/). Multiple arguments is separated with comma-character.
;rendering_args =

# You can configure the plugin to use a different browser binary instead of the pre-packaged version of Chromium.
# Please note that this is not recommended, since you may encounter problems if the installed version of Chrome/Chromium is not
# compatible with the plugin.
;rendering_chrome_bin =

# Instruct how headless browser instances are created. Default is 'default' and will create a new browser instance on each request.
# Mode 'clustered' will make sure that only a maximum of browsers/incognito pages can execute concurrently.
# Mode 'reusable' will have one browser instance and will create a new incognito page on each request.
;rendering_mode =

# When rendering_mode = clustered you can instruct how many browsers or incognito pages can execute concurrently. Default is 'browser'
# and will cluster using browser instances.
# Mode 'context' will cluster using incognito pages.
;rendering_clustering_mode =
# When rendering_mode = clustered you can define maximum number of browser instances/incognito pages that can execute concurrently..
;rendering_clustering_max_concurrency =

# Limit the maximum viewport width, height and device scale factor that can be requested.
;rendering_viewport_max_width =
;rendering_viewport_max_height =
;rendering_viewport_max_device_scale_factor =

# Change the listening host and port of the gRPC server. Default host is 127.0.0.1 and default port is 0 and will automatically assign
# a port not in use.
;grpc_host =
;grpc_port =

[enterprise]
# Path to a valid Grafana Enterprise license.jwt file
;license_path =

[feature_toggles]
# enable features, separated by spaces
;enable =

[date_formats]
# For information on what formatting patterns that are supported https://momentjs.com/docs/#/displaying/

# Default system date format used in time range picker and other places where full time is displayed
;full_date = YYYY-MM-DD HH:mm:ss

# Used by graph and other places where we only show small intervals
;interval_second = HH:mm:ss
;interval_minute = HH:mm
;interval_hour = MM/DD HH:mm
;interval_day = MM/DD
;interval_month = YYYY-MM
;interval_year = YYYY

# Experimental feature
;use_browser_locale = false

# Default timezone for user preferences. Options are 'browser' for the browser local timezone or a timezone name from IANA Time Zone database, e.g. 'UTC' or 'Europe/Amsterdam' etc.
;default_timezone = browser

[expressions]
# Enable or disable the expressions functionality.
;enabled = true
EOF
	judge "生成 grafana.ini 配置文件 "
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
    # listen 80, 443 --> Mock website https://${currentHost}
    # proxy pass
    # /portainer/ --> proxy_pass http://portainer:9000/;
    nginx:
        image: nginx:alpine
        container_name: nginx
        restart: always
        environment: 
            TZ: Asia/Shanghai
        expose:
            - 443
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
            - 443
        volumes:
            - /etc/fuckGFW/trojan-go/config.json:/etc/trojan-go/config.json
            # Store data on logserver
            - /root/git/logserver/${currentHost}/trojan-go/error.log:/etc/trojan-go/error.log           
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
        expose:
            - 37211
            - 37212
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
    #5. cadvisor -> container advisor / monitor  
    #--> Working      
    cadvisor:
        image: google/cadvisor:latest
        container_name: cadvisor
        restart: always
        environment: 
            TZ: Asia/Shanghai
        expose: 
            - 8080
        volumes:
            - /:/rootfs
            - /var/run:/var/run
            - /sys:/sys
            - /var/lib/docker/:/var/lib/docker
            - /dev/disk/:/dev/disk
        networks: 
            - net
    #6. prometheus -> monitor virtual machines
    #--> Working
    prometheus:
        image: prom/prometheus:latest
        container_name: prometheus
        restart: always
        environment: 
            TZ: Asia/Shanghai
        expose: 
            - 9090
        volumes:
            - /etc/fuckGFW/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml 
            - /root/git/logserver/${currentHost}/prometheus/groups/:/root/prometheus/groups/
            - /root/git/logserver/${currentHost}/prometheus/groups/:/usr/local/prometheus/groups/ 
            - /root/git/logserver/${currentHost}/prometheus/rules/:/root/prometheus/rules/
            - /root/git/logserver/${currentHost}/prometheus/rules/:/usr/local/prometheus/rules/ 
        networks: 
            - net
    #7. grafana -> monitor UI
    #--> Working
    grafana:
        image: grafana/grafana:latest
        container_name: grafana
        restart: always
        environment: 
        #https://grafana.com/docs/grafana/latest/administration/configuration/
        #GF_<SectionName>_<KeyName>
            TZ: Asia/Shanghai
            GF_SERVER_PROTOCOL: http
            GF_SERVER_HTTP_PORT: 3000
            GF_SERVER_DOMAIN: ${currentHost}
            GF_SERVER_ROOT_URL: "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
            GF_SERVER_SERVE_FROM_SUB_PATH: "true"
            GF_SECURITY_ADMIN_USER: root
            GF_SECURITY_ADMIN_PASSWORD: "abc123abc"
            GF_SERVER_ENABLE_GZIP: 'true'
            GF_USERS_ALLOW_SIGN_UP: 'true'
            GF_USERS_VIEWERS_CAN_EDIT: 'true'
            GF_AUTH_ANONYMOUS_ENABLED: 'true'
            GF_AUTH_ANONYMOUS_ORG_NAME: Main Org.
            GF_AUTH_ANONYMOUS_ORG_ROLE: Viewer
            GF_ANALYTICS_REPORTING_ENABLED: 'false'
            GF_ANALYTICS_CHECK_FOR_UPDATES: 'false'
        volumes:
            - /root/git/logserver/${currentHost}/grafana/:/etc/grafana/
            - /etc/fuckGFW/grafana/grafana.ini:/etc/grafana/grafana.ini
            - /root/git/logserver/${currentHost}/grafana/lib:/var/lib/grafana 
        expose:
            - 3000
        networks: 
            - net
    #8. Portainer -> Docker UI
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
	judge "生成 docker-compose.yml 配置文件 "
}
#-----------------------------------------------------------------------------#
# 查看 Nginx 配置文件
function show_nginx_conf {
	print_start "查看 Nginx 配置文件 "
	print_info "/etc/fuckGFW/nginx/conf.d/${currentHost}.conf"
	cat /etc/fuckGFW/nginx/conf.d/${currentHost}.conf
	judge "查看 Nginx 配置文件 "
}
#-----------------------------------------------------------------------------#
# 查看 xray 配置文件
function show_xray_conf {
	print_start "查看 xray 配置文件 "
	print_info "/etc/fuckGFW/xray/config.json"
	cat /etc/fuckGFW/xray/config.json
	judge "查看 xray 配置文件 "	
}
#-----------------------------------------------------------------------------#
# 查看 trojan-go 配置文件
function show_trojan_go_conf {
	print_start "查看 trojan-go 配置文件 "
	print_info "/etc/fuckGFW/trojan-go/config.json"
	cat /etc/fuckGFW/trojan-go/config.json
	judge "查看 trojan-go 配置文件 "	
}
#-----------------------------------------------------------------------------#
# 查看 v2ray 配置文件
function show_v2ray_conf {
	print_start "查看 v2ray 配置文件 "
	print_info "/etc/fuckGFW/v2ray/config.json"
	cat /etc/fuckGFW/v2ray/config.json
	judge "查看 v2ray 配置文件 "	
}
#-----------------------------------------------------------------------------#
# 查看 docker-compose.yml 配置文件
function show_docker_compose_yml {
	print_start "查看 docker-compose.yml 配置文件 "
	print_info "/etc/fuckGFW/docker/${currentHost}/docker-compose.yml"
	cat /etc/fuckGFW/docker/${currentHost}/docker-compose.yml
	judge "查看 docker-compose.yml 配置文件 "
}
#-----------------------------------------------------------------------------#
# generate access.log & error.log for nginx
function generate_access_log_error_log_nginx {
	print_start "Generate access.log & error.log for nginx "
	if [[ -f "$HOME/git/logserver/${currentHost}/nginx/access.log" ]];then
		print_info "nginx access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/nginx/
		touch access.log
		judge "Generate nginx access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/nginx/error.log" ]];then
		print_info "nginx error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/nginx/
		touch error.log
		judge "Generate nginx error.log "
	fi
}
#-----------------------------------------------------------------------------#
# generate access.log & error.log for trojan-go
function generate_access_log_error_log_trojan_go {
	print_start "Generate error.log for trojan-go "
	if [[ -f "$HOME/git/logserver/${currentHost}/trojan-go/error.log" ]];then
		print_info "trojan-go error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/trojan-go/
		touch error.log
		judge "Generate trojan-go error.log "
	fi
}
#-----------------------------------------------------------------------------#
# generate access.log & error.log for v2ray
function generate_access_log_error_log_v2ray {
	print_start "Generate access.log & error.log for v2ray "
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/access.log" ]];then
		print_info "v2ray access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch access.log
		judge "Generate v2ray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/error.log" ]];then
		print_info "v2ray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch error.log
		judge "Generate v2ray error.log "
	fi
}
#-----------------------------------------------------------------------------#
# generate access.log & error.log for xray
function generate_access_log_error_log_xray {
	print_start "Generate access.log & error.log for xray "
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/access.log" ]];then
		print_info "xray access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch access.log
		judge "Generate xray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/error.log" ]];then
		print_info "xray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch error.log
		judge "Generate xray error.log "
	fi
}
#-----------------------------------------------------------------------------#
# generate access.log & error.log
function generate_access_log_error_log {
	print_start "Generate access.log & error.log for nginx trojan-go v2ray xray "
	if [[ -f "$HOME/git/logserver/${currentHost}/nginx/access.log" ]];then
		print_info "nginx access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/nginx/
		touch access.log
		judge "Generate nginx access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/nginx/error.log" ]];then
		print_info "nginx error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/nginx/
		touch error.log
		judge "Generate nginx error.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/trojan-go/error.log" ]];then
		print_info "trojan-go error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/trojan-go/
		touch error.log
		judge "Generate trojan-go error.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/access.log" ]];then
		print_info "v2ray access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch access.log
		judge "Generate v2ray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/error.log" ]];then
		print_info "v2ray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch error.log
		judge "Generate v2ray error.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/access.log" ]];then
		print_info "xray access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch access.log
		judge "Generate xray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/error.log" ]];then
		print_info "xray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch error.log
		judge "Generate xray error.log "
	fi
	judge "Generate access.log & error.log for nginx trojan-go v2ray xray "
}
#-----------------------------------------------------------------------------#
# show access.log & error.log
function show_error_log {
	print_start "Show error.log for nginx trojan-go v2ray xray "
	echoContent yellow " ---> nginx"
	tail -n 20 $HOME/git/logserver/${currentHost}/nginx/error.log
	echoContent yellow " ---> trojan-go"
	tail -n 20 $HOME/git/logserver/${currentHost}/trojan-go/error.log
	echoContent yellow " ---> v2ray"
	tail -n 20 $HOME/git/logserver/${currentHost}/v2ray/error.log
	echoContent yellow " ---> xray"
	tail -n 20 $HOME/git/logserver/${currentHost}/xray/error.log
	judge "Show error.log for nginx trojan-go v2ray xray "
}
#-----------------------------------------------------------------------------#
# show error.log for nginx
function show_error_log_nginx {
	print_start "Show error.log for nginx "
	echoContent yellow " ---> nginx"
	tail -n 20 $HOME/git/logserver/${currentHost}/nginx/error.log
	judge "Show error.log for nginx "
}
#-----------------------------------------------------------------------------#
# show access.log for nginx
function show_access_log_nginx {
	print_start "Show access.log for nginx "
	echoContent yellow " ---> nginx"
	tail -n 20 $HOME/git/logserver/${currentHost}/nginx/access.log
	judge "Show access.log for nginx "
}
#-----------------------------------------------------------------------------#
# show error.log for trojan-go
function show_error_log_trojan_go {
	print_start "Show error.log for trojan-go "
	echoContent yellow " ---> trojan-go"
	tail -n 20 $HOME/git/logserver/${currentHost}/trojan-go/error.log
	judge "Show error.log for trojan-go "
}
#-----------------------------------------------------------------------------#
# show error.log for v2ray
function show_error_log_v2ray {
	print_start "Show error.log for v2ray "
	echoContent yellow " ---> v2ray"
	tail -n 20 $HOME/git/logserver/${currentHost}/v2ray/error.log
	judge "Show error.log for v2ray "
}
#-----------------------------------------------------------------------------#
# show access.log for v2ray
function show_access_log_v2ray {
	print_start "Show access.log for v2ray "
	echoContent yellow " ---> v2ray"
	tail -n 20 $HOME/git/logserver/${currentHost}/v2ray/access.log
	judge "Show access.log for v2ray "
}
#-----------------------------------------------------------------------------#
# show error.log for xray
function show_error_log_xray {
	print_start "Show error.log for xray "
	echoContent yellow " ---> xray"
	tail -n 20 $HOME/git/logserver/${currentHost}/xray/error.log
	judge "Show error.log for xray "
}
#-----------------------------------------------------------------------------#
# show access.log for xray
function show_access_log_xray {
	print_start "Show access.log for xray "
	echoContent yellow " ---> xray"
	tail -n 20 $HOME/git/logserver/${currentHost}/xray/access.log
	judge "Show access.log for xray "
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
function init_webmin_ssl {
	print_start "初始化webmin SSL证书 "
	
	if [[ -f "/etc/fuckGFW/webmin/backup/check" ]]; then
		print_error "已经备份过，不需重复备份！"
	else
		print_info "备份webmin配置文件到 /etc/fuckGFW/webmin/ "
		mkdir -p /etc/fuckGFW/webmin/backup
		cd /etc/fuckGFW/webmin/backup
		touch check
		cp -pf /etc/webmin/miniserv.* /etc/fuckGFW/webmin/backup
	fi

	if [[ -d "$HOME/.acme.sh/${currentHost}" ]] && [[ -f "$HOME/.acme.sh/${currentHost}/${currentHost}.key" ]] && [[ -f "$HOME/.acme.sh/${currentHost}/${currentHost}.cer" ]]; then
		print_info "写入 ${currentHost} SSL证书 "

		if [[ -f "/etc/webmin/check" ]]; then
			print_error "已经写入过SSL证书，不需重复写入！"
		else
			cd /etc/webmin
			touch check
			cat $HOME/.acme.sh/${currentHost}/${currentHost}.key > /etc/webmin/miniserv.pem
			cat $HOME/.acme.sh/${currentHost}/${currentHost}.cer >> /etc/webmin/miniserv.pem
			cat $HOME/.acme.sh/$currentHost/ca.cer > /etc/webmin/miniserv.ca
			echo "extracas=/etc/webmin/miniserv.ca" >> /etc/webmin/miniserv.conf
			print_info "重启 webmin.service "
			systemctl stop webmin.service
			sleep 2
			systemctl start webmin.service
		fi
	else
		print_error "未找到SSL证书！ "
	fi
	judge "初始化webmin SSL证书 "
}
#-----------------------------------------------------------------------------#
# 清理域名
function clear_myHostDomain {
	# print_start "重新初始化 服务器域名 "
	rm -f $HOME/.myHostDomain
	# print_info "清理完成"
	# judge "重新初始化 服务器域名 "
}
#-----------------------------------------------------------------------------#
# 清理UUID
function clear_currentUUID {
	# print_start "重新初始化 服务器域名 "
	rm -f $HOME/.currentUUID
	# print_info "清理完成"
	# judge "重新初始化 服务器域名 "
}
#-----------------------------------------------------------------------------#
# 设置 current Host Domain 
function set_current_host_domain {
	print_start "设置 current Host Domain "
	if [[ -f "$HOME/.myHostDomain" ]]; then
		print_error "已经设置服务器域名，无需重复设置！"
		currentHost=$(cat $HOME/.myHostDomain)
	else
		print_info "初始化 SmartTool v3 "
		print_info "$HOME/.myHostDomain "
		read -r -p "请设置服务器域名：" inputHostName
			if [ $inputHostName ]; then
				print_info "----- 服务器域名 ----"
				print_error "${inputHostName}"
				print_info "----- 服务器域名 ----"
				echo "${inputHostName}" > $HOME/.myHostDomain
			else
				print_error "未输入域名，使用默认域名: ${defaultHost}"
				print_info "----- 默认服务器域名 ----"
				print_error "${defaultHost}"
				print_info "----- 默认服务器域名 ----"
				echo "${defaultHost}" > $HOME/.myHostDomain
			fi
		currentHost=$(cat $HOME/.myHostDomain)
	fi
	WORKDIR="/etc/fuckGFW/docker/${currentHost}/"
	LOGDIR="/root/git/logserver/${currentHost}/"
	judge "设置 current Host Domain "
}
#-----------------------------------------------------------------------------#
# 设置 current UUID 
function set_current_uuid {
	print_start "设置 current UUID "
	if [[ -f "$HOME/.currentUUID" ]]; then
		currentUUID=$(cat $HOME/.currentUUID)
	else
		print_info "$HOME/.currentUUID"
		local tempUUID
		tempUUID=$(cat /proc/sys/kernel/random/uuid)
		cat <<EOF >$HOME/.currentUUID
${tempUUID}
EOF
	currentUUID=$(cat $HOME/.currentUUID)
	fi
	judge "设置 current UUID "
}
#-----------------------------------------------------------------------------#
# 生成 clash -> account 配置文件 
function generate_vmess_trojan_account {
	print_start "生成 clash -> account 配置文件 "
	print_info "/etc/fuckGFW/clash/config.yml"
	cat <<EOF >/etc/fuckGFW/clash/config.yml
  # Xray VMess 的配置
  - name: "${currentHost}-xrayWS-${currentIP}"
    type: vmess
    server: ${currentHost}
    port: 443
    uuid: ${currentUUID}
    alterId: 64
    cipher: auto
    tls: true
    network: ws
    ws-path: /${customPath}vmessws
    Host: ${currentHost}

  # v2ray VMess 的配置
  - name: "${currentHost}-v2rayWS-${currentIP}"
    type: vmess
    server: ${currentHost}
    port: 443
    uuid: ${currentUUID}
    alterId: 64
    cipher: auto
    tls: true
    network: ws
    ws-path: /${customPath}v2rayws
    Host: ${currentHost}

  # Trojan 的配置  
  - name: "${currentHost}-trojan-${currentIP}"
    type: trojan
    server: ${currentHost}
    port: 443
    password: ${currentUUID}
    sni: ${currentHost}

      - ${currentHost}-xrayWS-${currentIP}
      - ${currentHost}-v2rayWS-${currentIP}
      - ${currentHost}-trojan-${currentIP}

EOF
	cat /etc/fuckGFW/clash/config.yml
	judge "生成 clash -> account 配置文件 "
}
#-----------------------------------------------------------------------------#
# 安装Trojan-go
function install_standalone_trojan_go() {
	print_start "安装 trojan-go "
	print_info "项目地址 https://github.com/p4gefau1t/trojan-go "

	if ! ls /etc/fuckGFW/standalone/trojan-go/ | grep -q trojan-go; then

		version=$(curl -s https://api.github.com/repos/p4gefau1t/trojan-go/releases | jq -r .[0].tag_name)
		echoContent green " ---> Trojan-Go版本:${version}"
		if wget --help | grep -q show-progress; then
			wget -c -q --show-progress -P /etc/fuckGFW/standalone/trojan-go/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/trojan-go-linux-amd64.zip"
		else
			wget -c -P /etc/fuckGFW/standalone/trojan-go/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/trojan-go-linux-amd64.zip" >/dev/null 2>&1
		fi
		unzip -o /etc/fuckGFW/standalone/trojan-go/trojan-go-linux-amd64.zip -d /etc/fuckGFW/standalone/trojan-go >/dev/null
		rm -rf /etc/fuckGFW/standalone/trojan-go/trojan-go-linux-amd64.zip
	else
		echoContent green " ---> Trojan-Go版本:$(/etc/fuckGFW/standalone/trojan-go/trojan-go --version | awk '{print $2}' | head -1)"
		local reInstallTrojanStatus
		read -r -p "是否重新安装？[y/n]:" reInstallTrojanStatus
		if [[ "${reInstallTrojanStatus}" == "y" ]]; then
			rm -rf /etc/v2ray-agent/trojan/trojan-go*
			install_standalone_trojan_go "$1"
		fi
	fi
}
#-----------------------------------------------------------------------------#
# 更新Trojan-Go
updateTrojanGo() {
	print_start "更新Trojan-Go"
	if [[ ! -d "/etc/fuckGFW/standalone/trojan-go/" ]]; then
		echoContent red " ---> 没有检测到安装目录，请执行脚本安装内容"
		menu
		exit 0
	fi
	if find /etc/fuckGFW/standalone/trojan-go/ | grep -q "trojan-go"; then
		version=$(curl -s https://api.github.com/repos/p4gefau1t/trojan-go/releases | jq -r .[0].tag_name)
		echoContent green " ---> Trojan-Go版本:${version}"
		if [[ -n $(wget --help | grep show-progress) ]]; then
			wget -c -q --show-progress -P /etc/fuckGFW/standalone/trojan-go/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/${trojanGoCPUVendor}.zip"
		else
			wget -c -P /etc/fuckGFW/standalone/trojan-go/ "https://github.com/p4gefau1t/trojan-go/releases/download/${version}/${trojanGoCPUVendor}.zip" >/dev/null 2>&1
		fi
		unzip -o /etc/fuckGFW/standalone/trojan-go/${trojanGoCPUVendor}.zip -d /etc/v2ray-agent/trojan >/dev/null
		rm -rf /etc/fuckGFW/standalone/trojan-go/${trojanGoCPUVendor}.zip
		handleTrojanGo stop
		handleTrojanGo start
	else
		echoContent green " ---> 当前Trojan-Go版本:$(/etc/v2ray-agent/trojan/trojan-go --version | awk '{print $2}' | head -1)"
		if [[ -n $(/etc/v2ray-agent/trojan/trojan-go --version) ]]; then
			version=$(curl -s https://api.github.com/repos/p4gefau1t/trojan-go/releases | jq -r .[0].tag_name)
			if [[ "${version}" == "$(/etc/v2ray-agent/trojan/trojan-go --version | awk '{print $2}' | head -1)" ]]; then
				read -r -p "当前版本与最新版相同，是否重新安装？[y/n]:" reInstalTrojanGoStatus
				if [[ "${reInstalTrojanGoStatus}" == "y" ]]; then
					handleTrojanGo stop
					rm -rf /etc/v2ray-agent/trojan/trojan-go
					updateTrojanGo 1
				else
					echoContent green " ---> 放弃重新安装"
				fi
			else
				read -r -p "最新版本为：${version}，是否更新？[y/n]：" installTrojanGoStatus
				if [[ "${installTrojanGoStatus}" == "y" ]]; then
					rm -rf /etc/v2ray-agent/trojan/trojan-go
					updateTrojanGo 1
				else
					echoContent green " ---> 放弃更新"
				fi
			fi
		fi
	fi
}
# Trojan开机自启
installTrojanService() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 配置Trojan开机自启"
	if [[ -n $(find /bin /usr/bin -name "systemctl") ]]; then
		rm -rf /etc/systemd/system/trojan-go.service
		touch /etc/systemd/system/trojan-go.service

		cat <<EOF >/etc/systemd/system/trojan-go.service
[Unit]
Description=Trojan-Go - A unified platform for anti-censorship
Documentation=Trojan-Go
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=yes
ExecStart=/etc/v2ray-agent/trojan/trojan-go -config /etc/v2ray-agent/trojan/config_full.json
Restart=on-failure
RestartPreventExitStatus=23


[Install]
WantedBy=multi-user.target
EOF
		systemctl daemon-reload
		systemctl enable trojan-go.service
		echoContent green " ---> 配置Trojan开机自启成功"
	fi
}
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
			echoContent red "请手动执行【/etc/v2ray-agent/trojan/trojan-go -config /etc/v2ray-agent/trojan/config_full.json】，查看错误日志"
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
# 初始化Trojan-Go配置
initTrojanGoConfig() {

	echoContent skyBlue "\n进度 $1/${totalProgress} : 初始化Trojan配置"
	cat <<EOF >/etc/v2ray-agent/trojan/config_full.json
{
    "run_type": "server",
    "local_addr": "127.0.0.1",
    "local_port": 31296,
    "remote_addr": "127.0.0.1",
    "remote_port": 31300,
    "disable_http_check":true,
    "log_level":3,
    "log_file":"/etc/v2ray-agent/trojan/trojan.log",
    "password": [
        "${uuid}"
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
        "path": "/${customPath}tws",
        "host": "${domain}",
        "add":"${add}"
    },
    "router": {
        "enabled": false
    }
}
EOF
}
#-----------------------------------------------------------------------------#
# 安装 v2-ui
function install_v2_ui {
	bash <(curl -Ls https://blog.sprov.xyz/v2-ui.sh)
}
#-----------------------------------------------------------------------------#
# v2ray-agent BBR & 单机安装菜单
function external_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=================================================================="
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "---------------------------单机安装菜单-----------------------------"
	echoContent yellow "1.安装 v2ray-agent | 快捷方式 [vasma]"	
	echoContent yellow "2.安装 BBR"
	echoContent yellow "3.安装 v2-ui"
	echoContent yellow "4.安装 trojan-go"
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	1)
		InstallV2rayAgent
		;;
	2)
		install_bbr
		;;
	3)
		install_v2_ui
		;;
	4)
		install_standalone_trojan_go
		;;
	*)
		print_error "请输入正确的数字"
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 生成配置文件&Log文件菜单
function generate_conf_log_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=================================================================="
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "---------------------------生成配置文件-----------------------------"
	echoContent skyBlue "--> /etc/fuckGFW/"
	echoContent yellow "0.generate all conf"
	echoContent yellow "1.generate docker-compose.yml - fuckGFW"
	echoContent yellow "2.generate conf [Nginx]"
	echoContent yellow "3.generate conf [Trojan-go]"
	echoContent yellow "4.generate conf [v2ray]"
	echoContent yellow "5.generate conf [Xray]"
	echoContent yellow "6.generate conf [Prometheus]"
	echoContent yellow "7.generate conf [Grafana]"
	echoContent yellow "8.generate fake website - fuckGFW"
	echoContent skyBlue "---------------------------生成日志文件-----------------------------"
	echoContent skyBlue "--> $HOME/git/logserver/${currentHost}/"
	echoContent yellow "20.generate all logs"
	echoContent yellow "21.generate log [Nginx]"
	echoContent yellow "22.generate log [Trojan-go]"
	echoContent yellow "23.generate log [v2ray]"
	echoContent yellow "24.generate log [Xray]"
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	0)
		generate_docker_compose_yml
		generate_nginx_conf
		generate_trojan_go_conf
		generate_v2ray_conf
		generate_xray_conf
		generate_prometheus_conf
		generate_grafana_ini
		generate_fake_website
		;;
	1)
		generate_docker_compose_yml
		;;
	2)
		generate_nginx_conf
		;;
	3)
		generate_trojan_go_conf
		;;
	4)
		generate_v2ray_conf
		;;
	5)
		generate_xray_conf
		;;
	6)
		generate_prometheus_conf
		;;
	7)
		generate_grafana_ini
		;;
	8)
		generate_fake_website
		;;
	20)
		generate_access_log_error_log
		;;
	21)
		generate_access_log_error_log_nginx
		;;
	22)
		generate_access_log_error_log_trojan_go
		;;
	23)
		generate_access_log_error_log_v2ray
		;;
	24)
		generate_access_log_error_log_xray
		;;
	*)
		print_error "请输入正确的数字"
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 日志菜单
function log_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=================================================================="
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "---------------------------查看错误日志-----------------------------"
	echoContent yellow "1.show error.log [Nginx] "
	echoContent yellow "2.show error.log [Trojan-go]"
	echoContent yellow "3.show error.log [v2ray]"
	echoContent yellow "4.show error.log [vxray]"
	echoContent skyBlue "---------------------------查看访问日志-----------------------------"
	echoContent yellow "5.show access.log [Nginx] "
	echoContent yellow "6.show access.log [v2ray]"
	echoContent yellow "7.show access.log [vxray]"
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	1)
		show_error_log_nginx
		;;
	2)
		show_error_log_trojan_go
		;;
	3)
		show_error_log_v2ray
		;;
	4)
		show_error_log_xray
		;;
	5)
		show_access_log_nginx
		;;
	6)
		show_access_log_v2ray
		;;
	6)
		show_access_log_xray
		;;
	*)
		print_error "请输入正确的数字"
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 配置菜单
function conf_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=================================================================="
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "---------------------------查看配置文件-----------------------------"
	echoContent yellow "1.show docker-compose.yml"
	echoContent yellow "2.show nginx"
	echoContent yellow "3.show trojan-go"
	echoContent yellow "4.show v2ray"
	echoContent yellow "5.show xray"
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	1)
		show_docker_compose_yml
		;;
	2)
		show_nginx_conf
		;;
	3)
		show_trojan_go_conf
		;;
	4)
		show_v2ray_conf
		;;
	5)
		show_xray_conf
		;;
	*)
		print_error "请输入正确的数字"
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 主菜单
function menu() {
	clear
	cd "$HOME" || exit
	echoContent red "\n=================================================================="
	echoContent green "SmartTool：v0.266"
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "---------------------------安装软件-------------------------------"
	echoContent yellow "10.安装 全部程序"
	echoContent yellow "11.安装 prerequisite | 12.安装 acme.sh | 13.安装 bpytop | 14.安装 webmin"
	echoContent yellow "15.安装 docker CE | 16.安装 docker compose | 17.安装 git"
	echoContent skyBlue "---------------------------版本控制-------------------------------"  
	echoContent yellow "20.git init | 21.git clone | 22.git pull | 23.git push"
	echoContent yellow "24.更新日志、配置文件、动态数据到GitHub"
	echoContent skyBlue "---------------------------容器相关-------------------------------"
	echoContent yellow "30.One-key"
	echoContent yellow "31.docker-compose up"
	echoContent yellow "32.docker-compose down"
	echoContent yellow "33.docker status"
	echoContent yellow "34.generate conf & logs"
	echoContent skyBlue "---------------------------证书管理-------------------------------"
	echoContent yellow "40.show CA | 41.generate CA | 42.renew CA"
	echoContent skyBlue "---------------------------查看文件-------------------------------"
	echoContent yellow "43.查看配置文件"
	echoContent yellow "44.查看日志文件"
	echoContent yellow "45.show Account"
	echoContent skyBlue "---------------------------通用工具-------------------------------"
	echoContent yellow "61.UUID | 62.show IP | 63.bpytop | 64.set timezone"
	echoContent skyBlue "---------------------------脚本管理-------------------------------"
	echoContent yellow "0.更新脚本"
	echoContent yellow "1.设置域名 | 2.设置UUID | 3.默认UUID | 4.webmin ssl ｜ 5.外部工具"
	echoContent yellow "9.退出"
	echoContent red "=================================================================="
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
		sleep 2
		st
		;;
	23)
		github_push_toolbox
		github_push_logserver
		sleep 2
		st
		;;
	24)
		upload_logs_configuration_dynamic_data
		sleep 2
		menu
		;;
	30)
		generate_docker_compose_yml
		shutdown_docker_compose
		github_pull_toolbox
		github_pull_logserver
		generate_docker_compose_yml
		generate_ca
		renewalTLS
		generate_nginx_conf
		generate_xray_conf
		generate_trojan_go_conf
		generate_v2ray_conf
		generate_prometheus_conf
		generate_grafana_ini
		generate_access_log_error_log
		generate_fake_website
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
		generate_conf_log_menu
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
	43)
		conf_menu
		;;
	44)
		log_menu
		;;
	45)
		generate_vmess_trojan_account
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
	64)
		set_timezone
		;;
	0)
		updateSmartTool 1
		;;
	1)
		clear_myHostDomain
		set_current_host_domain
		;;
	2)
		clear_currentUUID
		set_current_uuid
		;;

	3)
		clear_currentUUID
		st
		;;
	4)
		init_webmin_ssl
		;;
	5)
		external_menu
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
set_current_host_domain
cronRenewTLS
menu
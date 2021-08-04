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
function inital_smart_tool() {
	# default Host
	defaultHost="k8s-master.cf"
	# default UUID
	defaultUUID="d8206743-b292-43d1-8200-5606238a5abb"
	# default Nagios server ip
	nagiosHostIP="104.199.212.122"
	# 随机路径
	customPath="rdxyzukwofngusfpmheud"

	# 自定义服务数组
	# array_service_description=("Network" "CPU" "Disk usage" "Memory" "Total procedures" "SSH" "Service v2ray" "Service xray" "Service trojan.go" "Service nginx" "Service httpd" "Service v2-ui" "Service x-ui" "Service webmin" "Service docker" "Service nrpe" "Service node_exporter" "HTTPS" "Certificate" "TCP 5666" "TCP 7080" "TCP 8080" "TCP 8443" "TCP 9100" "TCP 10000" )
	# array_check_command=("check_eth" "check_cpu_stats" "check_disk" "check_mem" "check_total_procs" "check_ssh" "check_v2ray" "check_xray" "check_trojan.go" "check_nginx" "check_httpd" "check_v2_ui" "check_x_ui" "check_webmin" "check_docker" "check_nrpe" "check_node_exporter" "check_http" "check_certificate_expires" "check_port_5666" "check_port_7080" "check_port_8080" "check_port_8443" "check_port_9100" "check_port_10000" )

	array_service_description=("Network sent" "Network receive" "CPU" "Disk" "Memory" "SSH" "Service xray" "Service nginx" "Service webmin" "Service nrpe" "Service ncpa" "HTTP" "Certificate" "TCP 443 nginx xray" "TCP 5666 nrpe" "TCP 5693 ncpa" "TCP 9100 node exporter" "TCP 9999 webmin" "Service node exporter" "Total process" )
	array_check_command=("check_ncpa_interface_sent" "check_ncpa_interface_receive" "check_ncpa_cpu" "check_ncpa_disk" "check_ncpa_memory" "check_ssh" "check_ncpa_service_xray" "check_ncpa_service_nginx" "check_ncpa_service_webmin" "check_ncpa_service_nrpe" "check_ncpa_service_ncpa_listener" "check_http" "check_certificate_expires" "check_port_443" "check_port_5666" "check_port_5693" "check_port_9100" "check_port_9999" "check_ncpa_service_node_exporter" "check_ncpa_processes")

	#定义变量
	# WORKDIR="/root/git/toolbox/Docker/docker-compose/${currentHost}/"
	SmartToolDir="/root/git/toolbox/Shell"
	# WORKDIR="/etc/fuckGFW/docker/${currentHost}/"
	# LOGDIR="/root/git/logserver/${currentHost}/"
	GITHUB_REPO_TOOLBOX="/root/git/toolbox"
	GITHUB_REPO_LOGSERVER="/root/git/logserver"
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
function print_complete() {
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
	print_start "安装 wget lsof tar unzip curl socat nmap bind-utils jq tree "
	if [[ -f "/etc/fuckGFW/prerequisite/check" ]]; then
		print_error "wget lsof tar unzip curl socat nmap bind-utils jq tree 已经安装，无需重复操作！"
	else
		print_info "安装进行中ing "	
		yum -y install wget lsof tar unzip curl socat nmap bind-utils jq tree >/dev/null 2>&1
		mkdir -p /etc/fuckGFW/prerequisite
		touch /etc/fuckGFW/prerequisite/check
	#  install dig and nslookup --> bind-utils
	fi
	print_complete "安装 wget lsof tar unzip curl socat nmap bind-utils jq tree "
}
#-----------------------------------------------------------------------------#
# Install acme.sh
function install_acme () {
	print_start "Install acme.sh "
	if [[ -d "$HOME/.acme.sh" ]] ; then
		print_error "acme.sh已经安装，无需重复操作！"
	else
		print_info "安装进行中ing "
		sudo curl -s https://get.acme.sh | sh -s email=$EMAIL >/dev/null 2>&1
	fi
	print_complete "安装 acme.sh "
}
#-----------------------------------------------------------------------------#
# Install bpytop
# https://github.com/aristocratos/bpytop
# PyPi (will always have latest version)
# Install or update to latest version
function install_bpytop () {
	print_start "Install bpytop "
	if [[ -f "/usr/local/bin/bpytop" ]]; then
		print_error "bpytop已经安装，无需重复操作！"
	else
		print_start "Install Prerequisites for Python3 "
		sudo yum -y install gcc libffi-devel python3-devel \
						openssl-devel \
						automake autoconf libtool make >/dev/null 2>&1
		print_info "安装进行中ing "
		print_complete "Install Prerequisites for Python3 "

		sudo pip3 install bpytop --upgrade >/dev/null 2>&1
		print_info "安装进行中ing "
		print_complete "1/2 Install bpytop "

		echo 'alias bpytop=/usr/local/bin/bpytop'>>~/.bash_profile
		source ~/.bash_profile 
		print_complete "2/2 添加 bpytop 命令到.bash_profile"
	fi
	print_complete "Install bpytop"
}
#-----------------------------------------------------------------------------#
# Install webmin
# https://webmin.com
# https://doxfer.webmin.com/Webmin/Installation
function install_webmin () {
	print_start "Install webmin "
	if [[ -d "/etc/webmin" ]]; then
		print_error "Webmin已经安装，无需重复操作！"
	else
		print_info "安装进行中ing "
		(echo "[Webmin]
name=Webmin Distribution Neutral
baseurl=http://download.webmin.com/download/yum
enabled=1
gpgcheck=1
gpgkey=http://www.webmin.com/jcameron-key.asc" >/etc/yum.repos.d/webmin.repo;)
		sleep 0.5
		sudo yum -y install webmin >/dev/null 2>&1
	fi
	print_complete "Install webmin "
}
#-----------------------------------------------------------------------------#
# Install Docker CE
# https://docs.docker.com/engine/install/centos/
function install_docker () {
	print_start "Install Docker CE "
	if [[ -f "/usr/bin/docker" ]]; then
		print_error "Docker CE已经安装，无需重复操作！"
	else
		print_info "安装进行中ing "
		sudo yum -y remove docker \
						docker-client \
						docker-client-latest \
						docker-common \
						docker-latest \
						docker-latest-logrotate \
						docker-logrotate \
						docker-engine >/dev/null 2>&1
		print_complete "1/3 Uninstall old versions of Docker CE "
		
		sudo yum -y install yum-utils >/dev/null 2>&1
		sudo yum-config-manager \
				--add-repo \
				https://download.docker.com/linux/centos/docker-ce.repo  >/dev/null 2>&1
		print_complete "2/3 Set up the repository for Docker "
		print_info "安装进行中ing "
		sudo yum -y install docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
		sudo systemctl start docker
		sudo systemctl enable docker
		print_complete "3/3 Install Docker Engine "
	fi
	print_complete "Install Docker CE "
}
#-----------------------------------------------------------------------------#
# Install Docker Compose
# https://docs.docker.com/compose/install/#install-compose
function install_docker_compose () {
	print_start "Install docker compose "
	if [[ -f "/usr/local/bin/docker-compose" ]]; then
		print_error "docker compose已经安装，无需重复操作！"
	else
		sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1
		sudo chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
		sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose >/dev/null 2>&1
		docker-compose --version
		print_info "安装进行中ing "
	fi
	print_complete "Install docker compose "
}
#-----------------------------------------------------------------------------#
# 卸载 docker CE & docker compose 
function uninstall_docker_and_docker_compose () {
	print_start "卸载 docker CE & docker compose "
	print_info "Uninstall the Docker Engine, CLI, and Containerd packages "
	yum -y remove docker-ce docker-ce-cli containerd.io

	print_info "Delete all images, containers, and volumes "
	rm -rf /var/lib/docker
	rm -rf /var/lib/containerd

	print_info "Uninstall docker compose"
	rm -f /usr/local/bin/docker-compose

	print_complete "卸载 docker CE & docker compose "
}
#-----------------------------------------------------------------------------#
# Install Git
# https://git-scm.com
function install_git () {
	print_start "Install Git "
	print_info "安装进行中ing "
	if [[ -f "/usr/bin/git" ]]; then
		print_error "Git已经安装，无需重复操作！"
	else
		sudo yum -y install git >/dev/null 2>&1
	fi
	print_complete "Install Git "
}
#-----------------------------------------------------------------------------#
# Install nginx
function install_nginx () {
	print_start "Install Nginx - port: 7080"
	if [[ -d "/etc/nginx" ]]; then
		print_error "Nginx已经安装，无需重复操作！"
	else
		print_info "安装进行中ing "
		sudo yum -y install nginx >/dev/null 2>&1

		# /etc/nginx/nginx.conf
		# listen       80 default_server;
		# listen       [::]:80 default_server;
		if cat /etc/nginx/nginx.conf | grep "listen       7080 default_server;" ; then
			print_error "已经设置端口：7080，无需重复设置！"
		else
			print_info "设置IPv4 端口为 7080"
			sed -i 's!listen       80 default_server;!listen       7080 default_server;!g' /etc/nginx/nginx.conf
		fi

		if cat /etc/nginx/nginx.conf | grep "listen       \[\:\:\]\:7080 default_server;" ; then
			print_error "已经设置端口：7080，无需重复设置！"
		else
			print_info "设置IPv6 端口为 7080"
			sed -i 's!listen       \[\:\:\]\:80 default_server;!listen       \[\:\:\]\:7080 default_server;!g' /etc/nginx/nginx.conf
		fi
	# systemctl reload nginx
	systemctl enable nginx
	systemctl restart nginx
	fi
	print_complete "Install Nginx - port: 7080 "
}
#-----------------------------------------------------------------------------#
# 安装 apache httpd
function install_apache_httpd {
	print_start "安装 apache httpd, 并设置端口：8080"
	if [[ -d "/etc/httpd" ]]; then
		print_error "apache httpd已安装，无需重复操作！"
	else
		print_info "安装进行中ing "
		yum -y install httpd >/dev/null 2>&1
		# /etc/httpd/conf/httpd.conf
		if cat /etc/httpd/conf/httpd.conf | grep "Listen 8080" ; then
			print_error "已经设置端口：8080，无需重复设置！"
		else
			sed -i 's!Listen 80!Listen 8080!g' /etc/httpd/conf/httpd.conf
		fi
		# systemctl reload httpd
		systemctl enable httpd
		systemctl restart httpd
	fi
	print_complete "安装 apache httpd, 并设置端口：8080"
}
#-----------------------------------------------------------------------------#
# Install nginx
function install_tomcat () {
	print_start "Install Tomcat "
	print_info "安装进行中ing "
	sudo yum -y install tomcat #>/dev/null 2>&1
	print_complete "Install Tomcat "
}
#-----------------------------------------------------------------------------#
# 安装 v2ray-agent
function install_v2ray_agent {
	# https://github.com/mack-a/v2ray-agent
	print_start "安装 v2ray-agent "
	wget -c -q --show-progress -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" 
	chmod 700 /root/install.sh
	print_complete "安装 v2ray-agent "
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
function docker_compose_down () {
	print_start "Shutdown Docker Compose "
	print_info "关闭 Docker Compose VM "
	cd $WORKDIR
	sudo docker-compose down
	print_complete "关闭 Docker Compose VM "
}
#-----------------------------------------------------------------------------#
# 启动docker-compose
function docker_compose_up () {
	print_start "启动 Docker Compose "
	cd $WORKDIR
	sudo docker-compose build
	sudo docker-compose up -d
	print_complete "启动 Docker Compose "
}
#-----------------------------------------------------------------------------#
# 查看Docker Images
function docker_images () {
	print_info "查看Docker Images "
	sudo docker images
}
#-----------------------------------------------------------------------------#
# 列出所有运行的docker container
function docker_container_ps () {
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
		print_error "Git文件夹已存在，无需初始化Git！"
	else
		git config --global user.name "root" 
		git config --global user.email "root@${currentHost}"
		git config --global pull.rebase false
		cd ~
		mkdir -p git
		cd git
		# ssh-keygen -t rsa -C fred.zhong@outlook.com
		# 免互动
		ssh-keygen -t rsa -C fred.zhong@outlook.com -P "" -f ~/.ssh/id_rsa
		print_info "请复制下面的Public key到GitHub "
		print_info "======== Public key========= "
		cat ~/.ssh/id_rsa.pub
		print_info "======== Public key End========= "
		print_complete "初始化 Git "
	
		read -r -p "将上面的 Public Key 输入到您的 GitHub 账户[y/n]: " answer_y_n
		if [[ "${answer_y_n}" == "y" ]]; then
			git_clone_toolbox
			git_clone_logserver

			github_pull_toolbox
			github_pull_logserver

			github_push_toolbox
			github_push_logserver
		else
			print_error "请设置好GitHub后，再继续进行！"
		fi
	fi
}
#-----------------------------------------------------------------------------#
# Git clone toolbox.git
function git_clone_toolbox () {
	print_start "Git clone ToolBox "
	if [[ -d "$HOME/git/" ]];then
		if [[ -d "$HOME/git/toolbox" ]];then
			print_error "toolbox文件夹已存在，无需重新clone！"
		else
			cd  $HOME/git/
			git clone git@github.com:linfengzhong/toolbox.git
			print_complete "Git clone ToolBox "

			echoContent green "同步下载 smart-tool-v3.sh 到根目录"
			#cp -pf $HOME/git/toolbox/Docker/docker-compose/$currentHost/smart-tool-v3.sh $HOME
			cp -pf ${SmartToolDir}/smart-tool-v3.sh $HOME
			chmod 700 $HOME/smart-tool-v3.sh
			aliasInstall
		fi
	else
		print_error "请先初始化Git！"
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
	print_complete "下载 -> Local ToolBox Repo "

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
	print_complete "上传ToolBox -> GitHub "
}
#-----------------------------------------------------------------------------#
# Git clone logserver.git
function git_clone_logserver () {
	print_start "Git clone logserver "
	if [[ -d "$HOME/git/logserver" ]];then
		print_error "logserver文件夹已存在，无需重新clone！"
	else
		cd  $HOME/git/
		git clone git@github.com:linfengzhong/logserver.git
		print_complete "Git clone logserver "
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
	print_complete "下载 -> Local logserver Repo "
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
	print_complete "上传logserver -> GitHub "
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

		#	if [[ -z "${centosVersion}" ]] && grep </etc/centos-release "release 8"; then
		#		centosVersion=8
		#	fi
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
	if [[ -d "$HOME/.acme.sh" ]]; then
		sleep 0.5
	else
		print_error "未发现acme.sh， 请安装后再运行生成证书！"
		exit 0
	fi

	if [[ -d "$HOME/.acme.sh/${currentHost}_ecc" ]] && [[ -f "$HOME/.acme.sh/${currentHost}_ecc/${currentHost}.key" ]] && [[ -f "$HOME/.acme.sh/${currentHost}_ecc/${currentHost}.cer" ]]; then
		mkdir -p $HOME/.acme.sh/${currentHost}
		chmod 755 $HOME/.acme.sh/${currentHost}
		cp -pf $HOME/.acme.sh/${currentHost}_ecc/*.* $HOME/.acme.sh/${currentHost}/
		print_info "Copy ECC to RSA "
	fi

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
	cp -pf $HOME/.acme.sh/$currentHost/*.cer /etc/fuckGFW/tls/
	cp -pf $HOME/.acme.sh/$currentHost/*.key /etc/fuckGFW/tls/
	cp -pf /etc/fuckGFW/tls/*.* /etc/fuckGFW/xray/${currentHost}/
	print_complete "生成网站证书 "
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
		print_info "${currentHost}"
		print_info "证书检查日期:$(date "+%F %H:%M:%S")"
		print_info "证书生成日期:$(date -d @"${modifyTime}" +"%F %H:%M:%S")"
		print_info "证书生成天数:${days}"
		print_info "证书剩余天数:"${tlsStatus}
		print_info "证书过期前最后一天自动更新，如更新失败请手动更新"

		if [[ ${remainingDays} -le 1 ]]; then
			print_info " ---> 重新生成证书"
			sh /root/.acme.sh/acme.sh  --issue  -d $currentHost --standalone --force
		else
			print_info " ---> 证书有效 <--- "
		fi
	else
		echoContent red " ---> 未安装 <--- "
		generate_ca
	fi
	print_complete "更新证书 "
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
	echo "30 1 * * * /bin/bash /etc/smart-tool/smart-tool-v3.sh RenewTLS" >>/etc/fuckGFW/backup_crontab.cron
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
	local newversion=$(cat /etc/smart-tool/smart-tool-v3.sh | grep 'SmartToolVersion=v' | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')

	print_info "---> 更新完毕"
	print_info "---> 当前版本:${newversion}"
	print_info "---> 请手动执行[st]打开脚本\n"
#	echoContent yellow "如更新不成功，请手动执行下面命令"
#	echoContent skyBlue "wget -P /root -N --no-check-certificate\
#  "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v3.sh" &&\
#  chmod 700 /root/smart-tool-v3.sh && /root/smart-tool-v3.sh"
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
	mkdir -p /etc/fuckGFW/xray/conf
	mkdir -p /etc/fuckGFW/trojan-go/
	mkdir -p /etc/fuckGFW/prometheus/groups
	mkdir -p /etc/fuckGFW/prometheus/rules
	mkdir -p /etc/fuckGFW/grafana/
	mkdir -p /etc/fuckGFW/webmin/
	mkdir -p /etc/fuckGFW/clash
	mkdir -p /etc/fuckGFW/standalone/trojan-go
	mkdir -p /etc/fuckGFW/nagios
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
	print_complete "设置时区： Asia/Shanghai "
}
#-----------------------------------------------------------------------------#
# Security-Enhanced Linux
# This guide is based on SELinux being disabled or in permissive mode. 
# Steps to do this are as follows.
function turn_off_selinux () {
	print_start "配置 Linux Rocky 8.4 / CentOS 8 服务器"
	sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
	#print_complete "Step 1: Security-Enhanced Linux"
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
	print_complete "生成 NGINX 配置文件 "
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
	print_complete "生成 xray 配置文件 "
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
	print_complete "生成 trojan-go 配置文件 "
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
	print_complete "生成 v2ray 配置文件 "
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
  # - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

  #  static_configs:
  #  - targets: ['localhost:9090']

  - job_name: "docker"
    static_configs:
    - targets: ['cadvisor:8080','taiwan3721.cf:8080','tokyo3721.cf:8080', 'singapore3721.cf:8080','seoul3721.cf:8080','losangeles3721.cf:8080','hongkong3721.cf:8080']

  - job_name: "linux"
    static_configs:
    # - targets: ['35.185.165.176:9100','34.80.73.27:9100','35.221.170.54:9100','104.199.212.122:9100']
    - targets: ['34.146.230.25:9100','35.221.204.2:9100','34.146.167.253:9100','35.247.169.26:9100','35.236.108.164:9100','34.96.129.154:9100','34.64.184.215:9100']
EOF
	print_complete "生成 prometheus 配置文件 "
}
#-----------------------------------------------------------------------------#
# 生成 grafana.ini 配置文件
function generate_grafana_ini {
	print_start "生成 grafana.ini 配置文件 "
	print_info "copy from GitHub to /etc/fuckGFW/grafana/grafana.ini"
	cp -pf ${GITHUB_REPO_TOOLBOX}/grafana/grafana.ini /etc/fuckGFW/grafana/
	chmod 666 /etc/fuckGFW/grafana/grafana.ini
	print_complete "生成 grafana.ini 配置文件 "
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
    # listen 7080, 7443 --> Mock website https://${currentHost}
    # proxy pass
    # /portainer/ --> proxy_pass http://portainer:9000/;
    nginx:
        image: nginx:alpine
        container_name: nginx
        restart: always
        environment: 
            TZ: Asia/Shanghai
        #expose:
        #    - 443
        ports:
            - 7080:80
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
        #expose:
        #    - 37211
        #    - 37212
        ports: 
            - 7443:443
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
    #7. node exporter -> provide dynamic data to prometheus via the port: 9100
    node_exporter:
        image: quay.io/prometheus/node-exporter:latest
        container_name: node_exporter
        environment: 
            TZ: Asia/Shanghai
        expose: 
            - 9100
        command:
            - '--path.rootfs=/host'
        network_mode: host
        pid: host
        restart: unless-stopped
        volumes:
          - '/:/host:ro,rslave'
    #8. grafana -> monitor UI
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
    #9. Portainer -> Docker UI
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
    #10. Rancher -> Docker UI
    #--> Working
#    portainer:
#        image: rancher/rancher
#        privileged: true
#        container_name: rancher
#        restart: always
#        environment: 
#            TZ: Asia/Shanghai
#        expose: 
#            - 80
#            - 433
#        networks: 
#            - net
networks: 
    net:
        driver: bridge
EOF
	print_complete "生成 docker-compose.yml 配置文件 "
}
#-----------------------------------------------------------------------------#
# 生成 docker-compose.yml 配置文件
function generate_docker_compose_yml_lite {
	print_start "生成 docker-compose.yml lite 配置文件 "
	print_info "/etc/fuckGFW/docker/${currentHost}/docker-compose.yml"
	cat <<EOF >/etc/fuckGFW/docker/${currentHost}/docker-compose.yml
version: '3.8'
services:
    #1. Nginx -> proxy server
    #2. trojan go -> fuck GFW
    #3. xray -> fuck GFW * Proxy Server
    #4. v2ray -> fuck GFW * Proxy Server
    #5. cadvisor -> container advisor / monitor  
    #--> Working      
    cadvisor:
        image: google/cadvisor:latest
        container_name: ${currentHost}_cadvisor
        restart: always
        environment: 
            TZ: Asia/Shanghai
        ports: 
            - 8080:8080
        volumes:
            - /:/rootfs
            - /var/run:/var/run
            - /sys:/sys
            - /var/lib/docker/:/var/lib/docker
            - /dev/disk/:/dev/disk
        networks: 
            - net
    #6. prometheus -> monitor virtual machines
    #7. node exporter -> provide dynamic data to prometheus via the port: 9100
    node_exporter:
        image: quay.io/prometheus/node-exporter:latest
        container_name: ${currentHost}_node_exporter
        environment: 
            TZ: Asia/Shanghai
        expose: 
            - 9100
        command:
           - '--path.rootfs=/host'
        network_mode: host
        pid: host
        restart: unless-stopped
        volumes:
          - '/:/host:ro,rslave'
    #8. grafana -> monitor UI
    #9. Portainer -> Docker UI
networks: 
    net:
        driver: bridge
EOF
	print_complete "生成 docker-compose.yml lite 配置文件 "
}
#-----------------------------------------------------------------------------#
# 查看 Nginx 配置文件
function show_nginx_conf {
	print_start "查看 Nginx 配置文件 "
	print_info "/etc/fuckGFW/nginx/conf.d/${currentHost}.conf"
	cat /etc/fuckGFW/nginx/conf.d/${currentHost}.conf
	print_complete "查看 Nginx 配置文件 "
}
#-----------------------------------------------------------------------------#
# 查看 xray 配置文件
function show_xray_conf {
	print_start "查看 xray 配置文件 "
	print_info "/etc/fuckGFW/xray/config.json"
	cat /etc/fuckGFW/xray/config.json
	print_complete "查看 xray 配置文件 "	
}
#-----------------------------------------------------------------------------#
# 查看 trojan-go 配置文件
function show_trojan_go_conf {
	print_start "查看 trojan-go 配置文件 "
	print_info "/etc/fuckGFW/trojan-go/config.json"
	cat /etc/fuckGFW/trojan-go/config.json
	print_complete "查看 trojan-go 配置文件 "	
}
#-----------------------------------------------------------------------------#
# 查看 v2ray 配置文件
function show_v2ray_conf {
	print_start "查看 v2ray 配置文件 "
	print_info "/etc/fuckGFW/v2ray/config.json"
	cat /etc/fuckGFW/v2ray/config.json
	print_complete "查看 v2ray 配置文件 "	
}
#-----------------------------------------------------------------------------#
# 查看 docker-compose.yml 配置文件
function show_docker_compose_yml {
	print_start "查看 docker-compose.yml 配置文件 "
	print_info "/etc/fuckGFW/docker/${currentHost}/docker-compose.yml"
	cat /etc/fuckGFW/docker/${currentHost}/docker-compose.yml
	print_complete "查看 docker-compose.yml 配置文件 "
}
#-----------------------------------------------------------------------------#
# 查看 prometheus 配置文件
function show_prometheus_conf {
	print_start "生成 prometheus 配置文件 "
	print_info "/etc/fuckGFW/prometheus/prometheus.yml"
	cat /etc/fuckGFW/prometheus/prometheus.yml
	print_complete "查看 prometheus 配置文件 "
}
#-----------------------------------------------------------------------------#
# 查看 grafana.ini 配置文件
function show_grafana_ini {
	print_start "查看 grafana.ini 配置文件 "
	print_info "/etc/fuckGFW/grafana/grafana.ini"
	cat /etc/fuckGFW/grafana/grafana.ini
	print_complete "查看 grafana.ini 配置文件 "
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
		print_complete "Generate nginx access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/nginx/error.log" ]];then
		print_info "nginx error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/nginx/
		touch error.log
		print_complete "Generate nginx error.log "
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
		print_complete "Generate trojan-go error.log "
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
		print_complete "Generate v2ray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/error.log" ]];then
		print_info "v2ray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch error.log
		print_complete "Generate v2ray error.log "
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
		print_complete "Generate xray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/error.log" ]];then
		print_info "xray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch error.log
		print_complete "Generate xray error.log "
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
		print_complete "Generate nginx access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/nginx/error.log" ]];then
		print_info "nginx error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/nginx/
		touch error.log
		print_complete "Generate nginx error.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/trojan-go/error.log" ]];then
		print_info "trojan-go error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/trojan-go/
		touch error.log
		print_complete "Generate trojan-go error.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/access.log" ]];then
		print_info "v2ray access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch access.log
		print_complete "Generate v2ray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/v2ray/error.log" ]];then
		print_info "v2ray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/v2ray/
		touch error.log
		print_complete "Generate v2ray error.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/access.log" ]];then
		print_info "xray access.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch access.log
		print_complete "Generate xray access.log "
	fi
	if [[ -f "$HOME/git/logserver/${currentHost}/xray/error.log" ]];then
		print_info "xray error.log 文件已存在，无需新建！ "
	else
		cd $HOME/git/logserver/${currentHost}/xray/
		touch error.log
		print_complete "Generate xray error.log "
	fi
	print_complete "Generate access.log & error.log for nginx trojan-go v2ray xray "
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
	print_complete "Show error.log for nginx trojan-go v2ray xray "
}
#-----------------------------------------------------------------------------#
# show error.log for nginx
function show_error_log_nginx {
	print_start "Show error.log for nginx "
	echoContent yellow " ---> nginx"
	tail -n 20 $HOME/git/logserver/${currentHost}/nginx/error.log
	print_complete "Show error.log for nginx "
}
#-----------------------------------------------------------------------------#
# show access.log for nginx
function show_access_log_nginx {
	print_start "Show access.log for nginx "
	echoContent yellow " ---> nginx"
	tail -n 20 $HOME/git/logserver/${currentHost}/nginx/access.log
	print_complete "Show access.log for nginx "
}
#-----------------------------------------------------------------------------#
# show error.log for trojan-go
function show_error_log_trojan_go {
	print_start "Show error.log for trojan-go "
	echoContent yellow " ---> trojan-go"
	tail -n 20 $HOME/git/logserver/${currentHost}/trojan-go/error.log
	print_complete "Show error.log for trojan-go "
}
#-----------------------------------------------------------------------------#
# show error.log for v2ray
function show_error_log_v2ray {
	print_start "Show error.log for v2ray "
	echoContent yellow " ---> v2ray"
	tail -n 20 $HOME/git/logserver/${currentHost}/v2ray/error.log
	print_complete "Show error.log for v2ray "
}
#-----------------------------------------------------------------------------#
# show access.log for v2ray
function show_access_log_v2ray {
	print_start "Show access.log for v2ray "
	echoContent yellow " ---> v2ray"
	tail -n 20 $HOME/git/logserver/${currentHost}/v2ray/access.log
	print_complete "Show access.log for v2ray "
}
#-----------------------------------------------------------------------------#
# show error.log for xray
function show_error_log_xray {
	print_start "Show error.log for xray "
	echoContent yellow " ---> xray"
	tail -n 20 $HOME/git/logserver/${currentHost}/xray/error.log
	print_complete "Show error.log for xray "
}
#-----------------------------------------------------------------------------#
# show access.log for xray
function show_access_log_xray {
	print_start "Show access.log for xray "
	echoContent yellow " ---> xray"
	tail -n 20 $HOME/git/logserver/${currentHost}/xray/access.log
	print_complete "Show access.log for xray "
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
	print_complete "添加随机伪装站点  "	
}
#-----------------------------------------------------------------------------#
# Upload logs & configuration & dynamic data
function upload_logs_configuration_dynamic_data () {
	#print_info "更新日志、配置文件、动态数据到GitHub "
	github_pull_logserver
	github_push_logserver
	#print_complete "更新日志、配置文件、动态数据到GitHub "	
}
#-----------------------------------------------------------------------------#
# 初始化 webmin SSL
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
			service webmin restart
		fi
	else
		print_error "未找到 RSA非对称加密算法 SSL证书！ "
		if [[ -d "$HOME/.acme.sh/${currentHost}_ecc" ]] && [[ -f "$HOME/.acme.sh/${currentHost}_ecc/${currentHost}.key" ]] && [[ -f "$HOME/.acme.sh/${currentHost}_ecc/${currentHost}.cer" ]]; then
		print_info "写入 ${currentHost}_ecc SSL证书 "

			if [[ -f "/etc/webmin/check" ]]; then
				print_error "已经写入过SSL证书，不需重复写入！"
			else
				cd /etc/webmin
				touch check
				cat $HOME/.acme.sh/${currentHost}_ecc/${currentHost}.key > /etc/webmin/miniserv.pem
				cat $HOME/.acme.sh/${currentHost}_ecc/${currentHost}.cer >> /etc/webmin/miniserv.pem
				cat $HOME/.acme.sh/${currentHost}_ecc/ca.cer > /etc/webmin/miniserv.ca
				echo "extracas=/etc/webmin/miniserv.ca" >> /etc/webmin/miniserv.conf
				print_info "重启 webmin.service "
				service webmin restart
			fi
		else
		print_error "未找到 ECC椭圆曲线加密算法 SSL证书！ "
		fi
	fi
	print_complete "初始化webmin SSL证书 "
}
#-----------------------------------------------------------------------------#
# 修改 webmin 端口：10000 -> 9999 
function init_webmin_port_9999 {
	print_start "修改webmin端口为 9999"

	if cat /etc/webmin/miniserv.conf | grep 10000  >/dev/null 2>&1 ; then
		sed -i 's/port=10000/port=9999/g' /etc/webmin/miniserv.conf
		sed -i 's/listen=10000/listen=9999/g' /etc/webmin/miniserv.conf
	else
		print_error "已经修改过端口, 无需重复操作！"
	fi

	print_complete "修改webmin端口为 9999"
}

#-----------------------------------------------------------------------------#
# 重启 webmin 服务
function restart_webmin_service {
	print_info "重启 webmin.service "
	service webmin restart
	systemctl restart webmin
	#systemctl status webmin
	print_complete "重启 webmin.service "
}

#-----------------------------------------------------------------------------#
# 清理域名
function clear_myHostDomain {
	# print_start "重新初始化 服务器域名 "
	rm -f $HOME/.myHostDomain
	# print_info "清理完成"
	# print_complete "重新初始化 服务器域名 "
}
#-----------------------------------------------------------------------------#
# 清理UUID
function clear_currentUUID {
	# print_start "重新初始化 服务器域名 "
	rm -f $HOME/.currentUUID
	# print_info "清理完成"
	# print_complete "重新初始化 服务器域名 "
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
	print_complete "设置 current Host Domain "

	hostnamectl set-hostname ${currentHost}
	hostnamectl status

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
	print_complete "设置 current UUID "
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
    port: 7443
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
    port: 7443
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
    port: 7443
    password: ${currentUUID}
    sni: ${currentHost}

      - ${currentHost}-xrayWS-${currentIP}
      - ${currentHost}-v2rayWS-${currentIP}
      - ${currentHost}-trojan-${currentIP}

EOF
	cat /etc/fuckGFW/clash/config.yml
	print_complete "生成 clash -> account 配置文件 "
}
#-----------------------------------------------------------------------------#
# 安装standalone xray
function install_standalone_xray() {
	checkCPUVendor
	installXray
	installXrayService
	initXrayConfig
	handleXray stop
	handleXray start
	checkGFWStatue
}
#-----------------------------------------------------------------------------#
# 检查CPU提供商
function checkCPUVendor() {
	if [[ -n $(which uname) ]]; then
		if [[ "$(uname)" == "Linux" ]];then
			case "$(uname -m)" in
			'amd64' | 'x86_64')
				xrayCoreCPUVendor="Xray-linux-64"
				v2rayCoreCPUVendor="v2ray-linux-64"
				trojanGoCPUVendor="trojan-go-linux-amd64"
			;;
			'armv8' | 'aarch64')
        		xrayCoreCPUVendor="Xray-linux-arm64-v8a"
				v2rayCoreCPUVendor="v2ray-linux-arm64-v8a"
				trojanGoCPUVendor="trojan-go-linux-armv8"
        	;;
			*)
        		echo "  不支持此CPU架构--->"
        		exit 1
        	;;
    		esac
		fi
	else
		pring_error "无法识别此CPU架构，默认amd64、x86_64 "
		xrayCoreCPUVendor="Xray-linux-64"
		v2rayCoreCPUVendor="v2ray-linux-64"
		trojanGoCPUVendor="trojan-go-linux-amd64"
	fi
}
#-----------------------------------------------------------------------------#
# 安装xray
function installXray() {
	print_start "安装standalone Xray"
	coreInstallType="2"

	if [[ "${coreInstallType}" != "1" ]]; then

		version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | jq -r .[].tag_name|head -1)

		print_info "Xray-core版本: ${version}"
		if wget --help | grep -q show-progress; then
			wget -c -q --show-progress -P /etc/fuckGFW/xray/ "https://github.com/XTLS/Xray-core/releases/download/${version}/${xrayCoreCPUVendor}.zip"
		else
			wget -c -P /etc/fuckGFW/xray/ "https://github.com/XTLS/Xray-core/releases/download/${version}/${xrayCoreCPUVendor}.zip" >/dev/null 2>&1
		fi

		unzip -o /etc/fuckGFW/xray/${xrayCoreCPUVendor}.zip -d /etc/fuckGFW/xray >/dev/null
		rm -rf /etc/fuckGFW/xray/${xrayCoreCPUVendor}.zip
		chmod 655 /etc/fuckGFW/xray/xray
	else
		print_info "Xray-core版本: $(/etc/fuckGFW/xray/xray --version | awk '{print $2}' | head -1)"
		read -r -p "是否更新、升级？[y/n]:" reInstallXrayStatus
		if [[ "${reInstallXrayStatus}" == "y" ]]; then
			rm -f /etc/fuckGFW/xray/xray
			installXray "$1"
		fi
	fi

	print_complete "安装standalone Xray"
}
#-----------------------------------------------------------------------------#
# Xray开机自启
function installXrayService() {
	print_info "配置Xray开机自启"
	if [[ -n $(find /bin /usr/bin -name "systemctl") ]]; then
		rm -rf /etc/systemd/system/xray.service
		touch /etc/systemd/system/xray.service
		execStart='/etc/fuckGFW/xray/xray run -confdir /etc/fuckGFW/xray/conf'
		cat <<EOF >/etc/systemd/system/xray.service
[Unit]
Description=Xray - A unified platform for anti-censorship
# Documentation=https://xtls.github.io https://github.com/XTLS
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
		print_complete "配置Xray开机自启成功"
	fi
}
#-----------------------------------------------------------------------------#
# 初始化Xray 配置文件
function initXrayConfig() {
	print_start "初始化Xray配置 "

	local uuid=
	if [[ -n "${currentUUID}" ]]; then
		read -r -p "读取到上次安装记录，是否使用上次安装时的UUID ？[y/n]:" historyUUIDStatus
		if [[ "${historyUUIDStatus}" == "y" ]]; then
			uuid=${currentUUID}
			print_info "使用成功"
		else
			uuid=$(/etc/fuckGFW/xray/xray uuid)
		fi
	fi

	if [[ -z "${uuid}" ]];then
		print_info "请输入自定义UUID[需合法]，[回车]随机UUID"
		read -r -p 'UUID:' customUUID

		if [[ -n ${customUUID} ]];then
			uuid=${customUUID}
		else
			uuid=$(/etc/fuckGFW/xray/xray uuid)
		fi

	fi

	if [[ -z "${uuid}" ]]; then
		echoContent red "\n ---> uuid读取错误，重新生成"
		uuid=$(/etc/fuckGFW/xray/xray uuid)
	fi

	print_info "${uuid}"

	rm -rf /etc/fuckGFW/xray/conf/*

	# log
	cat <<EOF >/etc/fuckGFW/xray/conf/00_log.json
{
  "log": {
    "error": "/etc/fuckGFW/xray/error.log",
    "loglevel": "warning"
  }
}
EOF

	# outbounds
	if [[ -n "${pingIPv6}" ]]; then
		cat <<EOF >/etc/fuckGFW/xray/conf/10_ipv6_outbounds.json
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
		cat <<EOF >/etc/fuckGFW/xray/conf/10_ipv4_outbounds.json
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
	cat <<EOF >/etc/fuckGFW/xray/conf/11_dns.json
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
		fallbacksList='{"dest":31296,"xver":1},{"alpn":"h2","dest":31302,"xver":0}'
		cat <<EOF >/etc/fuckGFW/xray/conf/04_trojan_TCP_inbounds.json
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

	# VLESS_WS_TLS
	if echo "${selectCustomInstallType}" | grep -q 1 || [[ "$1" == "all" ]]; then
		fallbacksList=${fallbacksList}',{"path":"/'${customPath}'ws","dest":31297,"xver":1}'
		cat <<EOF >/etc/fuckGFW/xray/conf/03_VLESS_WS_inbounds.json
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


	# trojan_grpc
	if echo ${selectCustomInstallType} | grep -q 2 || [[ "$1" == "all" ]]; then
		if ! echo ${selectCustomInstallType} | grep -q 5 && [[ -n ${selectCustomInstallType} ]];then
			fallbacksList=${fallbacksList//31302/31304}
		fi

		cat <<EOF >/etc/fuckGFW/xray/conf/04_trojan_gRPC_inbounds.json
{
    "inbounds": [
        {
            "port": 31304,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "tag": "trojangRPCTCP",
            "settings": {
                "clients": [
                    {
                        "password": "${uuid}",
                        "email": "${domain}_trojan_gRPC"
                    }
                ],
                "fallbacks": [
                    {
                        "dest": "31300"
                    }
                ]
            },
            "streamSettings": {
                "network": "grpc",
                "grpcSettings": {
                    "serviceName": "${customPath}trojangrpc"
                }
            }
        }
    ]
}
EOF
	fi


	# VMess_WS
	if echo "${selectCustomInstallType}" | grep -q 3 || [[ "$1" == "all" ]]; then
		fallbacksList=${fallbacksList}',{"path":"/'${customPath}'vws","dest":31299,"xver":1}'
		cat <<EOF >/etc/fuckGFW/xray/conf/05_VMess_WS_inbounds.json
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
		cat <<EOF >/etc/fuckGFW/xray/conf/06_VLESS_gRPC_inbounds.json
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
	cat <<EOF >/etc/fuckGFW/xray/conf/02_VLESS_TCP_inbounds.json
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
          "certificateFile": "/etc/fuckGFW/tls/${currentHost}.cer",
          "keyFile": "/etc/fuckGFW/tls/${currentHost}.key",
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
}
#-----------------------------------------------------------------------------#
# 操作xray
function handleXray() {
	if [[ -n $(find /bin /usr/bin -name "systemctl") ]] && ls /etc/systemd/system/ | grep -q xray.service; then
		if [[ -z $(pgrep -f "xray/xray") ]] && [[ "$1" == "start" ]]; then
			systemctl start xray.service
		elif [[ -n $(pgrep -f "xray/xray") ]] && [[ "$1" == "stop" ]]; then
			systemctl stop xray.service
		fi
	fi

	sleep 0.8

	if [[ "$1" == "start" ]]; then
		if [[ -n $(pgrep -f "xray/xray") ]]; then
			echoContent green " ---> Xray启动成功"
		else
			echoContent red "xray启动失败"
			echoContent red "请手动执行【/etc/fuckGFW/xray/xray -confdir /etc/fuckGFW/xray/conf】，查看错误日志"
			exit 0
		fi
	elif [[ "$1" == "stop" ]]; then
		if [[ -z $(pgrep -f "xray/xray") ]]; then
			echoContent green " ---> Xray关闭成功"
		else
			echoContent red "xray关闭失败"
			echoContent red "请手动执行【ps -ef|grep -v grep|grep xray|awk '{print \$2}'|xargs kill -9】"
			exit 0
		fi
	fi
}
# 验证整个服务是否可用
function checkGFWStatue() {
	print_start "验证服务启动状态"
	if [[ "${coreInstallType}" == "1" ]] && [[ -n $(pgrep -f xray/xray) ]]; then
		echoContent green " ---> 服务启动成功"
	elif [[ "${coreInstallType}" == "2" || "${coreInstallType}" == "3" ]] && [[ -n $(pgrep -f v2ray/v2ray) ]]; then
		echoContent green " ---> 服务启动成功"
	else
		echoContent red " ---> 服务启动失败，请检查终端是否有日志打印"
		exit 0
	fi

}
#-----------------------------------------------------------------------------#
# 更新Xray
function update_Xray() {
	if [[ -z "${coreInstallType}" ]]; then
		if [[ -n "$1" ]]; then
			version=$1
		else
			version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | jq -r .[0].tag_name)
		fi

		print_info "Xray-core版本: ${version}"

		if wget --help | grep -q show-progress; then
			wget -c -q --show-progress -P /etc/fuckGFW/xray/ "https://github.com/XTLS/Xray-core/releases/download/${version}/${xrayCoreCPUVendor}.zip"
		else
			wget -c -P /etc/fuckGFW/xray/ "https://github.com/XTLS/Xray-core/releases/download/${version}/${xrayCoreCPUVendor}.zip" >/dev/null 2>&1
		fi

		unzip -o /etc/fuckGFW/xray/${xrayCoreCPUVendor}.zip -d /etc/fuckGFW/xray >/dev/null
		rm -rf /etc/fuckGFW/xray/${xrayCoreCPUVendor}.zip
		chmod 655 /etc/fuckGFW/xray/xray
		handleXray stop
		handleXray start
	else
		print_info "当前Xray-core版本: $(/etc/fuckGFW/xray/xray --version | awk '{print $2}' | head -1)"

		if [[ -n "$1" ]]; then
			version=$1
		else
			version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | jq -r .[0].tag_name)
		fi

		if [[ -n "$1" ]]; then
			read -r -p "回退版本为${version}，是否继续？[y/n]:" rollbackXrayStatus
			if [[ "${rollbackXrayStatus}" == "y" ]]; then
				print_info "当前Xray-core版本: $(/etc/fuckGFW/xray/xray --version | awk '{print $2}' | head -1)"

				handleXray stop
				rm -f /etc/fuckGFW/xray/xray
				updateXray "${version}"
			else
				print_info "放弃回退版本"
			fi
		elif [[ "${version}" == "v$(/etc/fuckGFW/xray/xray --version | awk '{print $2}' | head -1)" ]]; then
			read -r -p "当前版本与最新版相同，是否重新安装？[y/n]:" reInstallXrayStatus
			if [[ "${reInstallXrayStatus}" == "y" ]]; then
				handleXray stop
				rm -f /etc/fuckGFW/xray/xray
				rm -f /etc/fuckGFW/xray/xray
				updateXray
			else
				print_info "放弃重新安装"
			fi
		else
			read -r -p "最新版本为：${version}，是否更新？[y/n]：" installXrayStatus
			if [[ "${installXrayStatus}" == "y" ]]; then
				rm -f /etc/fuckGFW/xray/xray
				updateXray
			else
				print_info "放弃更新"
			fi

		fi
	fi
}
#-----------------------------------------------------------------------------#
# 安装 xray_OneKey
function install_xray_onekey {
	wget -N --no-check-certificate -q -O xinstall.sh "https://raw.githubusercontent.com/wulabing/Xray_onekey/main/install.sh" && chmod +x xinstall.sh && bash xinstall.sh
}
#-----------------------------------------------------------------------------#
# 安装 v2-ui
function install_v2_ui {
	bash <(curl -Ls https://blog.sprov.xyz/v2-ui.sh)
}
#-----------------------------------------------------------------------------#
# 安装 x-ui
function install_x_ui {
	bash <(curl -Ls https://raw.githubusercontent.com/sprov065/x-ui/master/install.sh)
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Check MyServers Folder
function customize_nagios_server_check_myservers_folder {
	print_info "Step 1: Nagios 自定义文件夹 /usr/local/nagios/etc/objects/myservers "
	mkdir -p /usr/local/nagios/etc/objects/myservers
	chown nagios:nagios /usr/local/nagios/etc/objects/myservers
	chmod 777 /usr/local/nagios/etc/objects/myservers
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Nagios.cfg
function customize_nagios_server_nagios_cfg {
	print_info "Step 2-1: Nagios 主配置文件集 /usr/local/nagios/etc/nagios.cfg"
	if [[ ! -f "/usr/local/nagios/etc/nagios.cfg" ]]; then
		print_error "Nagios 主配置文件不存在，请确认是否正确安装Nagios core！"
		exit 0
	else
		if cat /usr/local/nagios/etc/nagios.cfg | grep "cfg_dir=/usr/local/nagios/etc/objects/myservers" >/dev/null; then
   			print_error "nagios.cfg 已定制过，无需重复操作！"
		else
			# 注释掉内容
			sed -i 's!cfg_file=/usr/local/nagios/etc/objects/localhost.cfg!#cfg_file=/usr/local/nagios/etc/objects/localhost.cfg!g' /usr/local/nagios/etc/nagios.cfg
			# 添加myserver文件夹
			sed -i 's!#cfg_dir=/usr/local/nagios/etc/servers!cfg_dir=/usr/local/nagios/etc/objects/myservers!g' /usr/local/nagios/etc/nagios.cfg
		fi
	fi

 	print_info "Step 2-2: Nagios 主配置通讯录 /usr/local/nagios/etc/objects/contacts.cfg"
	if [[ ! -f "/usr/local/nagios/etc/objects/contacts.cfg" ]]; then
		print_error "Nagios 通讯录文件不存在，请确认是否正确安装Nagios core！"
		exit 0
	else
		if cat /usr/local/nagios/etc/objects/contacts.cfg | grep "nagios@localhost" >/dev/null; then
			read -r -p "请输入Nagios Admin 邮件地址 : " NagiosAdminMail
			if [ $NagiosAdminMail ]; then
				sed -i 's!nagios@localhost!'"$NagiosAdminMail"'!g' /usr/local/nagios/etc/objects/contacts.cfg
			else
				print_info "未检测到输入邮件地址！"
			fi
		else
   			print_error "contacts.cfg 已定制过，无需重复操作！"
		fi
	fi

  	print_info "Step 2-3: Nagios 主配置时间段 /usr/local/nagios/etc/objects/timeperiods.cfg"
	print_info "Step 2-4: Nagios 主配置命令集 /usr/local/nagios/etc/objects/commands.cfg"
	print_info "Step 2-5: Nagios 主配置模版集 /usr/local/nagios/etc/objects/templates.cfg"
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Myservers
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Myservers two
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Myservers Three
function customize_nagios_server_myservers_three {
	print_info "Step 3: Nagios 自定义文件夹 独立服务器配置文件"

	# NagiosClientDomain1
	# NagiosClientIP1
	local array_service_and_command_index=0
	local servicexx
	local temp_array_service_description
	local temp_array_check_command
	local temp_array_check_command1

	read -r -p "请输入Nagios client address : " NagiosClientDomain1
	if [ $NagiosClientDomain1 ]; then
		print_info "Step 3-1: 使用输入地址: ${NagiosClientDomain1}"
	else
		print_error "Step 3-1: 未检测到输入，使用默认地址: ${currentHost}"
		NagiosClientDomain1=${currentHost}
	fi
	
	NagiosClientIP1=$(ping ${NagiosClientDomain1} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
	print_info "Step 3-2: 输入的服务器IP地址: \c"
	echoContent white "${NagiosClientIP1}"

	print_info "Step 3-3: 独立服务器配置文件 /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg"
	cat <<EOF > /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg
# Define a host for the remote machine
define host {
    host_name                       $NagiosClientDomain1
    alias                           $NagiosClientDomain1
    address                         $NagiosClientIP1
    notifications_enabled           1                       ; Host notifications are enabled
    event_handler_enabled           1                       ; Host event handler is enabled
    flap_detection_enabled          1                       ; Flap detection is enabled
    process_perf_data               1                       ; Process performance data
    retain_status_information       1                       ; Retain status information across program restarts
    retain_nonstatus_information    1                       ; Retain non-status information across program restarts
    check_period                    24x7                    ; By default, Linux hosts are checked round the clock
    check_interval                  5                       ; Actively check the host every 5 minutes
    retry_interval                  1                       ; Schedule host check retries at 1 minute intervals
    max_check_attempts              10                      ; Check each Linux host 10 times (max)
    check_command                   check-host-alive        ; Default command to check Linux hosts
    notification_period             24x7                    ; Send host notifications at any time 24x7 or workhours
    notification_interval           120                     ; Resend notifications every 2 hours
    notification_options            d,u,r                   ; Only send notifications for specific host states
                                                            ; d = send notifications on a DOWN state
                                                            ; u = send notifications on an UNREACHABLE state
                                                            ; r = send notifications on recoveries (OK state)
                                                            ; f = send notifications when the host starts and stops flapping
                                                            ; s = send notifications when scheduled downtime starts and ends
                                                            ; n = none
                                                            ; If you do not specify any notification options, Nagios will assume that you want notifications to be sent out for all possible states. 
    contacts                        nagiosadmin             ; This is a list of the short names of the contacts that should be notified whenever there are problems (or recoveries) with this host. Multiple contacts should be separated by commas.
                                                            ; Useful if you want notifications to go to just a few people and don't want to configure contact groups. You must specify at least one contact or contact group in each host definition.
    contact_groups                  admins                  ; Notifications get sent to the admins by default
}
EOF
	for servicexx in "${array_service_description[@]}"
	do
		temp_array_service_description=${array_service_description[array_service_and_command_index]}
		temp_array_check_command=${array_check_command[array_service_and_command_index]}

		if [[ "$temp_array_check_command" != "check_ssh" && "$temp_array_check_command" != "check_certificate_expires" && "$temp_array_check_command" != "check_ssl_certificate" && "$temp_array_check_command" != "check_http" && "$temp_array_check_command" != "check_port_5666" && "$temp_array_check_command" != "check_port_7080" && "$temp_array_check_command" != "check_port_8080" && "$temp_array_check_command" != "check_port_8443" && "$temp_array_check_command" != "check_port_9100" && "$temp_array_check_command" != "check_port_10000" && "$temp_array_check_command" != "check_ncpa_processes" ]]; then
			temp_array_check_command1="check_nrpe!"$temp_array_check_command
		else
			temp_array_check_command1=$temp_array_check_command
		fi
		cat <<EOF >> /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg
# Define a service to check $temp_array_service_description on the remote machine.
define service {
    use                     generic-service
    host_name               $NagiosClientDomain1
    service_description     $temp_array_service_description
    check_command           $temp_array_check_command1
}
EOF
		let array_service_and_command_index++
	done

	chown nagios:nagios /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg
	chmod 777 /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg

	# cat /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg

}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Host
function customize_nagios_server_myservers_host {
	# print_info "Step 3: Nagios 自定义文件夹 独立服务器配置文件"
	# NagiosClientDomain1
	# NagiosClientIP1

	read -r -p "请输入Nagios 被监控主机域名: " NagiosClientDomain1
	if [ $NagiosClientDomain1 ]; then
		print_info "被监控主机域名: \c"
		echoContent white "${NagiosClientDomain1}"
	else
		print_error "未检测到输入，使用默认域名: ${currentHost}"
		NagiosClientDomain1=${currentHost}
	fi
	
	NagiosClientIP1=$(ping ${NagiosClientDomain1} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
	print_info "被监控主机IP地址: \c"
	echoContent white "${NagiosClientIP1}"

	print_info "Step 3: Nagios 自定义服务器 /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg"
	cat <<EOF > /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg
# Define a host for the remote machine
define host {
    host_name                       $NagiosClientDomain1
    alias                           $NagiosClientDomain1
    address                         $NagiosClientIP1
    notifications_enabled           1                       ; Host notifications are enabled
    event_handler_enabled           1                       ; Host event handler is enabled
    flap_detection_enabled          1                       ; Flap detection is enabled
    process_perf_data               1                       ; Process performance data
    retain_status_information       1                       ; Retain status information across program restarts
    retain_nonstatus_information    1                       ; Retain non-status information across program restarts
    check_period                    24x7                    ; By default, Linux hosts are checked round the clock
    check_interval                  5                       ; Actively check the host every 5 minutes
    retry_interval                  1                       ; Schedule host check retries at 1 minute intervals
    max_check_attempts              10                      ; Check each Linux host 10 times (max)
    check_command                   check-host-alive        ; Default command to check Linux hosts
    notification_period             24x7                    ; Send host notifications at any time 24x7 or workhours
    notification_interval           120                     ; Resend notifications every 2 hours
    notification_options            d,u,r                   ; Only send notifications for specific host states
                                                            ; d = send notifications on a DOWN state
                                                            ; u = send notifications on an UNREACHABLE state
                                                            ; r = send notifications on recoveries (OK state)
                                                            ; f = send notifications when the host starts and stops flapping
                                                            ; s = send notifications when scheduled downtime starts and ends
                                                            ; n = none
                                                            ; If you do not specify any notification options, Nagios will assume that you want notifications to be sent out for all possible states. 
    contacts                        nagiosadmin             ; This is a list of the short names of the contacts that should be notified whenever there are problems (or recoveries) with this host. Multiple contacts should be separated by commas.
                                                            ; Useful if you want notifications to go to just a few people and don't want to configure contact groups. You must specify at least one contact or contact group in each host definition.
    contact_groups                  admins                  ; Notifications get sent to the admins by default
}

EOF
	chown nagios:nagios /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg
	chmod 777 /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg

	if [[ "${NagiosClientDomain1}" == "k8s-master.cf" ]] ; then

		local array_service_description_master=("Service docker" "Service x-ui" "Service nagios")
		local array_check_command_master=("check_ncpa_service_docker" "check_ncpa_service_x-ui" "check_ncpa_service_nagios")
		local servicexx_master
		local array_service_and_command_index_master=0
		local temp_array_service_description_master
		local temp_array_check_command_master

		print_info "发现Master主控，开始进行额外配置"

		for servicexx_master in "${array_service_description_master[@]}"
		do

		temp_array_service_description_master=${array_service_description_master[array_service_and_command_index_master]}
		temp_array_check_command_master=${array_check_command_master[array_service_and_command_index_master]}

		cat <<EOF >> /usr/local/nagios/etc/objects/myservers/${NagiosClientDomain1}.cfg
# Define a service to check $temp_array_service_description_master on the remote machine.
define service {
    use                     normal-service
    host_name               $NagiosClientDomain1
    service_description     $temp_array_service_description_master
    check_command           $temp_array_check_command_master
}

EOF
		let array_service_and_command_index_master++
		done
	else
		print_info "未发现Master主控，无需额外配置"
	fi

}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Services
function customize_nagios_server_myservers_services {
	print_info "Step 4: Nagios 自定义服务集 /usr/local/nagios/etc/objects/myservers/services.cfg"
	cat <<EOF > /usr/local/nagios/etc/objects/myservers/services.cfg
define service {
    name                            normal-service          ; The 'name' of this service template
    active_checks_enabled           1                       ; Active service checks are enabled
    passive_checks_enabled          1                       ; Passive service checks are enabled/accepted
    parallelize_check               1                       ; Active service checks should be parallelized (disabling this can lead to major performance problems)
    obsess_over_service             1                       ; We should obsess over this service (if necessary)
    check_freshness                 0                       ; Default is to NOT check service 'freshness'
    notifications_enabled           1                       ; Service notifications are enabled
    event_handler_enabled           1                       ; Service event handler is enabled
    flap_detection_enabled          1                       ; Flap detection is enabled
    process_perf_data               1                       ; Process performance data
    retain_status_information       1                       ; Retain status information across program restarts
    retain_nonstatus_information    1                       ; Retain non-status information across program restarts
    is_volatile                     0                       ; The service is not volatile
    check_period                    24x7                    ; The service can be checked at any time of the day
    max_check_attempts              3                       ; Re-check the service up to 3 times in order to determine its final (hard) state
    check_interval                  10                      ; Check the service every 10 minutes under normal conditions
    retry_interval                  2                       ; Re-check the service every two minutes until a hard state can be determined
    contact_groups                  admins                  ; Notifications get sent out to everyone in the 'admins' group
    notification_options            w,u,c,r                 ; Send notifications about warning, unknown, critical, and recovery events
    notification_interval           60                      ; Re-notify about service problems every hour
    notification_period             24x7                    ; Notifications can be sent out at any time
    register                        0                       ; DON'T REGISTER THIS DEFINITION - ITS NOT A REAL SERVICE, JUST A TEMPLATE!
}
EOF

	local array_service_and_command_index=0
	local servicexx
	local temp_array_service_description
	local temp_array_check_command
	local temp_array_check_command1

	for servicexx in "${array_service_description[@]}"
	do
		temp_array_service_description=${array_service_description[array_service_and_command_index]}
		temp_array_check_command=${array_check_command[array_service_and_command_index]}

#		if [[ "$temp_array_check_command" != "check_ssh" && "$temp_array_check_command" != "check_certificate_expires" && "$temp_array_check_command" != "check_ssl_certificate" && "$temp_array_check_command" != "check_http" && "$temp_array_check_command" != "check_port_5666" && "$temp_array_check_command" != "check_port_5693" && "$temp_array_check_command" != "check_port_7080" && "$temp_array_check_command" != "check_port_8080" && "$temp_array_check_command" != "check_port_8443" && "$temp_array_check_command" != "check_port_9100" && "$temp_array_check_command" != "check_port_10000" && "$temp_array_check_command" != "check_ncpa_processes" && "$temp_array_check_command" != "check_ncpa_cpu" && "$temp_array_check_command" != "check_ncpa_memory" ]]; then
		if [[ "$temp_array_check_command" = "check_eth" || "$temp_array_check_command" = "check_disk" ]]; then
			temp_array_check_command1="check_nrpe!"$temp_array_check_command
		else
			temp_array_check_command1=$temp_array_check_command
		fi
		cat <<EOF >> /usr/local/nagios/etc/objects/myservers/services.cfg
# Define a service to check $temp_array_service_description on the remote machine.
define service {
    use                     normal-service
    hostgroup_name          Fuck GFW
    service_description     $temp_array_service_description
    check_command           $temp_array_check_command1
}
EOF
		let array_service_and_command_index++
	done
	chown nagios:nagios /usr/local/nagios/etc/objects/myservers/services.cfg
	chmod 777 /usr/local/nagios/etc/objects/myservers/services.cfg
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Host Group
function customize_nagios_server_myservers_host_group {
	print_info "Step 5: Nagios 自定义主机组 /usr/local/nagios/etc/objects/myservers/host_group.cfg"

	# 读取文件名到数组
	local search_dir="/usr/local/nagios/etc/objects/myservers"
	for entry in $search_dir/*
	do
		if [ -f $entry ]; then
			arr=(${arr[*]} $entry)
		fi
	done

	local Myservers_Host_Group=$currentHost
	#if [[ -f "/usr/local/nagios/etc/objects/myservers/host_group.cfg" ]] && cat /usr/local/nagios/etc/objects/myservers/host_group.cfg | grep "# 2021 July 19th" >/dev/null; then
	#	print_error "host_group.cfg 已经配置过了！"
	#else
	# 遍历数组，生成myservers
		local myservers_index=0
		for i in ${arr[*]}
		do
		# 正则表达式 ${var##*/}  --> 左边算起的最后一个/字符左边的内容
		# print_info "${arr[myservers_index]##*/}"
		
		tmpMyservers_Host_Group=${arr[myservers_index]##*/}
		if [[ "${tmpMyservers_Host_Group}" == "host_group.cfg" ]] || [[ "${tmpMyservers_Host_Group}" == "service_group.cfg" ]] || [[ "${tmpMyservers_Host_Group}" == "mycommands.cfg" ]] || [[ "${tmpMyservers_Host_Group}" == "services.cfg" ]] || [[ "${tmpMyservers_Host_Group}" == "$currentHost"".cfg" ]] ; then
		#if [[ "${coreInstallType}" == "1" ]] && [[ -n $(pgrep -f xray/xray) ]]; then
			# skip
			# print_error "skip file"
			# echoContent white "${tmpMyservers_Host_Group}"
			let myservers_index++
		else
			Myservers_Host_Group=$Myservers_Host_Group","${tmpMyservers_Host_Group%.*}
			# print_info "$Myservers_Host_Group"
			let myservers_index++
		fi
		done

	# 写入文件
		cat <<EOF > /usr/local/nagios/etc/objects/myservers/host_group.cfg
# 2021 July 19th
define hostgroup{
	hostgroup_name  Fuck GFW
	alias           Fuck GFW
	members         $Myservers_Host_Group
	}
EOF

		chown nagios:nagios /usr/local/nagios/etc/objects/myservers/host_group.cfg
		chmod 777 /usr/local/nagios/etc/objects/myservers/host_group.cfg
	#fi
	# print_info "展示 host_group.cfg"
	# cat /usr/local/nagios/etc/objects/myservers/host_group.cfg
	# print_complete "Step 4: Nagios 服务器组配置文件： /usr/local/nagios/etc/objects/myservers/host_group.cfg"
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Service Group
function customize_nagios_server_myservers_service_group {
	print_info "Step 6: Nagios 自定义服务组 /usr/local/nagios/etc/objects/myservers/service_group.cfg"

	# 读取文件名到数组
	local search_dir="/usr/local/nagios/etc/objects/myservers"
	local array_host
	for host_group_member in $search_dir/*
	do
		if [ -f $host_group_member ]; then
			array_host=(${array_host[*]} $host_group_member)
		fi
	done

	cat <<EOF > /usr/local/nagios/etc/objects/myservers/service_group.cfg
# 2021 July 21st
EOF

	local Service_Type
	local Service_Group_Member=$currentHost
	local tmpService_Group_Member
	local Service_Type_Index=0
	local i=0
	# local array_service=(v2ray xray trojan.go nginx httpd v2-ui x-ui webmin docker)
	# local array_service=("Service v2ray" "Service xray" "Service trojan.go" "Service nginx" "Service httpd" "Service v2-ui" "Service x-ui" "Service webmin" "Service docker" "CPU statistics" "Memory usage" Ping "Service nrpe" "Service node_exporter")
	# local array_service=("CPU statistics" "Current users" "Disk usage" "Memory usage" "Total procedures" "SSH" "Ping" "Service v2ray" "Service xray" "Service trojan.go" "Service nginx" "Service httpd" "Service v2-ui" "Service x-ui" "Service webmin" "Service docker" "Service nrpe" "Service node_exporter")
	
	# echo ${array_service[@]}
	# for i in ${array_service[*]} 
	# 数组元素有空格，要用双引号
	for i in "${array_service_description[@]}"
	do
		Service_Type=${array_service_description[Service_Type_Index]}
		# Service_Group_Member=$Service_Group_Member",Service "${Service_Type}
		Service_Group_Member=$Service_Group_Member","${Service_Type}
		local e=0
		local Myservers_Host_Index=0
		for e in ${array_host[*]}
		do
		tmpService_Group_Member=${array_host[Myservers_Host_Index]##*/}
		if [[ "${tmpService_Group_Member}" == "host_group.cfg" ]] || [[ "${tmpService_Group_Member}" == "service_group.cfg" ]] || [[ "${tmpService_Group_Member}" == "mycommands.cfg" ]] || [[ "${tmpService_Group_Member}" == "services.cfg" ]] || [[ "${tmpService_Group_Member}" == "$currentHost"".cfg" ]] ; then
			# print_error "skip file"
			# echoContent white "${tmpService_Group_Member}"
			let Myservers_Host_Index++
		else
			# Service_Group_Member=$Service_Group_Member","${tmpService_Group_Member%.*}",Service "${Service_Type}
			Service_Group_Member=$Service_Group_Member","${tmpService_Group_Member%.*}","${Service_Type}
			# print_info "$Service_Group_Member"
			let Myservers_Host_Index++
		fi
		done
		cat <<EOF >> /usr/local/nagios/etc/objects/myservers/service_group.cfg
define servicegroup{
	servicegroup_name	${Service_Type#*Service }
	alias			${Service_Type#*Service }
	members			${Service_Group_Member}
	}
EOF
		Service_Group_Member=$currentHost
		let Service_Type_Index++
	done
	chown nagios:nagios /usr/local/nagios/etc/objects/myservers/service_group.cfg
	chmod 777 /usr/local/nagios/etc/objects/myservers/service_group.cfg

}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Command
function customize_nagios_server_myservers_command {
	print_info "Step 7: Nagios 自定义命令集 /usr/local/nagios/etc/objects/myservers/mycommands.cfg"
	cat <<EOF > /usr/local/nagios/etc/objects/myservers/mycommands.cfg
################################################################################
# 2021 July 19th defined COMMANDS
################################################################################

define command {
    command_name    check_nrpe
    command_line    \$USER1\$/check_nrpe -H \$HOSTADDRESS$ -t 30 -c \$ARG1\$ \$ARG2\$
}

define command {
    command_name    check_ncpa
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$
}

define command {
    command_name    check_load
    command_line    \$USER1\$/check_load -w \$ARG1\$ -c \$ARG2\$
}

define command {
    command_name    check_certificate_expires
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 443 -w 0.5 -c 1 -t 5 -S -D 30
}

define command {
    command_name    check_ssl_certificate
    command_line    \$USER1\$/check_ssl_certificate -H \$HOSTADDRESS$ -c 10 -w 20
}

define command {
    command_name    check_port_80
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 80 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_443
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 443 -w 0.5 -c 1 -t 5 -S
}

define command {
    command_name    check_port_5666
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 5666 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_5693
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 5693 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_7080
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 7080 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_8080
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 8080 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_8443
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 8443 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_9100
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 9100 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_port_9999
    command_line    \$USER1\$/check_tcp -H \$HOSTADDRESS$ -p 9999 -w 0.2 -c 0.5 -t 5
}

define command {
    command_name    check_ncpa_cpu
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M cpu/percent --warning 90 --critical 95
}

define command {
    command_name    check_ncpa_memory
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M memory/virtual -w 80 -c 90 -u G
}

define command {
    command_name    check_ncpa_processes
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M processes -w 160 -c 200
}

#define command {
#    command_name    check_ncpa_processes
#    command_line    check_ncpa!-t 'mytoken' -P 5693 -M processes -w 150 -c 200
#}

define command {
    command_name    check_ncpa_service_nginx
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=nginx,status=running
}

define command {
    command_name    check_ncpa_service_node_exporter
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=node_exporter,status=running
}

define command {
    command_name    check_ncpa_service_nrpe
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=nrpe,status=running
}

define command {
    command_name    check_ncpa_service_webmin
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=webmin,status=running
}

define command {
    command_name    check_ncpa_service_xray
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=xray,status=running
}

define command {
    command_name    check_ncpa_service_docker
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=docker,status=running
}

define command {
    command_name    check_ncpa_service_nagios
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=nagios,status=running
}

define command {
    command_name    check_ncpa_service_x-ui
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=x-ui,status=running
}

define command {
    command_name    check_ncpa_service_ncpa_listener
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M services -q service=ncpa_listener,status=running
}

define command {
    command_name    check_ncpa_interface_sent
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M 'interface/eth0/bytes_sent' -d -u m -w 10 -c 100
}

define command {
    command_name    check_ncpa_interface_receive
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M 'interface/eth0/bytes_recv' -d -u m -w 10 -c 100
}

define command {
    command_name    check_ncpa_disk_free
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M 'disk/logical/|/free' --warning 10: --critical 5: -u G
}

define command {
    command_name    check_ncpa_disk_used
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M 'disk/logical/|/used' --warning 10: --critical 5: -u G
}

define command {
    command_name    check_ncpa_disk
    command_line    \$USER1\$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1\$ -t 'mytoken' -P 5693 -M 'disk/logical/|' --warning 10: --critical 5: -u G
}

EOF
	chown nagios:nagios /usr/local/nagios/etc/objects/myservers/mycommands.cfg
	chmod 777 /usr/local/nagios/etc/objects/myservers/mycommands.cfg
}
#-----------------------------------------------------------------------------#
# 定制 /etc/hosts
function customize_nagios_server_hosts_ip {
	print_info "Step 8: 编辑 /etc/hosts "
	if cat /etc/hosts | grep ${NagiosClientDomain1} >/dev/null; then
   		print_error "主机地址已经添加到/etc/hosts，无需重复操作！"
	else
		print_info "Step 8-1: 写入主机IP和域名到/etc/hosts "
		cat <<EOF >> /etc/hosts
${NagiosClientIP1} ${NagiosClientDomain1}
EOF
	fi
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server Myservers Show
function customize_nagios_server_myservers_show {
	print_info "Step 9: 服务器列表"
	print_info "#------------------------------# "

	local search_dir="/usr/local/nagios/etc/objects/myservers"
	for xxmember in $search_dir/*
	do
		if [ -f $xxmember ]; then
			myservers_member_arr=(${myservers_member_arr[*]} $xxmember)
		fi
	done

	local myservers_member_index=0
	local myservers_member_count=0
	local myserver_number=0

	for myservers_member_count in ${myservers_member_arr[*]}
	do
	# 正则表达式 ${var##*/}  --> 左边算起的最后一个/字符左边的内容
	tmpMyservers_Member=${myservers_member_arr[myservers_member_index]##*/}
		if [[ "${tmpMyservers_Member}" == "host_group.cfg" ]] || [[ "${tmpMyservers_Member}" == "service_group.cfg" ]] || [[ "${tmpMyservers_Member}" == "mycommands.cfg" ]] || [[ "${tmpMyservers_Member}" == "services.cfg" ]] ; then
			let myservers_member_index++
		else
			Myservers_Member=${tmpMyservers_Member%.*}
			print_info "# 服务器域名: \c"
			echoContent white "$Myservers_Member"
			let myservers_member_index++
			let myserver_number++
		fi
	done
	print_info "# 服务器总数: \c "
	echoContent green "$myserver_number"
	print_info "#------------------------------# "
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server 重启
function customize_nagios_server_restart {
	print_info "Step 10: 重启 Nagios 服务"
	systemctl restart nagios
	# systemctl status nagios
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Server
function customize_nagios_server {
	print_start "定制 Nagios Server "

	customize_nagios_server_check_myservers_folder
	customize_nagios_server_nagios_cfg
	# customize_nagios_server_myservers_three
	customize_nagios_server_myservers_host
	customize_nagios_server_myservers_services
	customize_nagios_server_myservers_host_group
	customize_nagios_server_myservers_service_group
	customize_nagios_server_myservers_command
	customize_nagios_server_hosts_ip
	customize_nagios_server_myservers_show
	customize_nagios_server_restart

	print_complete "定制 Nagios Server "
}

#-----------------------------------------------------------------------------#
# 定制 Nagios Client NRPE.cfg
function customize_nagios_client_nrpe_cfg {
	print_info "Step 1: Nagios 客户端配置文件： /usr/local/nagios/etc/nrpe.cfg "
	if [[ ! -f "/usr/local/nagios/etc/nrpe.cfg" ]]; then
		print_error "Nagios 客户端配置文件不存在，请确认是否正确安装Nagios NRPE！"
		exit 0
	else
		if [[ ! -f "/usr/local/nagios/etc/nrpe.cfg.bakcup" ]]; then
		cp -pf /usr/local/nagios/etc/nrpe.cfg /usr/local/nagios/etc/nrpe.cfg.backup
		else
			print_info "已备份 nrpe.cfg"
		fi

		# if cat /usr/local/nagios/etc/nrpe.cfg | grep "定制命令 - 2021 July 18th" >/dev/null; then
   		#	print_error "已定制过，无需重复操作！"
		# else
			print_info "Step 1-1: 添加Nagios 服务端IP # ALLOWED HOST ADDRESSES "
			# 注释掉内容
			local TMPnagiosHostIP
			read -r -p "请输入Nagios Server IP (留空使用默认地址): " TMPnagiosHostIP
			if [ $TMPnagiosHostIP ]; then
				print_info "Nagios Server IP : ${TMPnagiosHostIP}"
			else
				print_error "未检测到输入，将使用默认Nagios Server: \c "
				echoContent white "k8s-master.cf"
				TMPnagiosHostIP=$(ping k8s-master.cf -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')

				# TMPnagiosHostIP=${nagiosHostIP}
				print_info "使用默认 Nagios Server IP: \c "
				echoContent white "${TMPnagiosHostIP}"
			fi
			# 双引号可以用shell变量
			# sed -i "s/allowed_hosts=127.0.0.1,::1/allowed_hosts=127.0.0.1,::1,$TMPnagiosHostIP/g" /usr/local/nagios/etc/nrpe.cfg
			print_info "Step 1-2: 添加Command "
			cat <<EOF > /usr/local/nagios/etc/nrpe.cfg
log_facility=daemon
log_file=/usr/local/nagios/var/nrpe.log
# Values: 0=debugging off, 1=debugging on
debug=0
pid_file=/usr/local/nagios/var/nrpe.pid
server_port=5666
nrpe_user=nagios
nrpe_group=nagios
allowed_hosts=127.0.0.1,::1,$TMPnagiosHostIP
dont_blame_nrpe=0
# Values: 0=do not allow bash command substitutions,
#         1=allow bash command substitutions
allow_bash_command_substitution=0
command_timeout=60
connection_timeout=300
disable_syslog=0

# 定制命令 - 2021 July 18th
command[check_users]=/usr/local/nagios/libexec/check_users -w 5 -c 10
command[check_load]=/usr/local/nagios/libexec/check_load -r -w .15,.10,.05 -c .30,.25,.20
command[check_hda1]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /dev/hda1
command[check_zombie_procs]=/usr/local/nagios/libexec/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/local/nagios/libexec/check_procs -w 160 -c 200

command[check_mem]=/usr/local/nagios/libexec/check_mem -w 90 -c 95 -W 50 -C 80
command[check_swap]=/usr/local/nagios/libexec/check_swap -c 0

command[check_disk]=/usr/local/nagios/libexec/check_disk -w 30% -c 20% -p /
command[check_kernel]=/usr/local/nagios/libexec/check_kernel --warn-only

command[check_netint]=/usr/local/nagios/libexec/check_netinterfaces -n eth0 -f -k -z
command[check_cpu_stats]=/usr/local/nagios/libexec/check_cpu_stats.sh

command[check_v2ray]=/usr/local/nagios/libexec/check_service.sh -s v2ray
command[check_xray]=/usr/local/nagios/libexec/check_service.sh -s xray
command[check_trojan.go]=/usr/local/nagios/libexec/check_service.sh -s trojan-go
command[check_nginx]=/usr/local/nagios/libexec/check_service.sh -s nginx
command[check_httpd]=/usr/local/nagios/libexec/check_service.sh -s httpd

command[check_v2_ui]=/usr/local/nagios/libexec/check_service.sh -s v2-ui
command[check_x_ui]=/usr/local/nagios/libexec/check_service.sh -s x-ui
command[check_webmin]=/usr/local/nagios/libexec/check_service.sh -s webmin
command[check_docker]=/usr/local/nagios/libexec/check_service.sh -s docker
command[check_docker2]=/usr/local/nagios/libexec/check_docker -w 50 -c 80
command[check_nrpe]=/usr/local/nagios/libexec/check_service.sh -s nrpe
command[check_ncpa]=/usr/local/nagios/libexec/check_service.sh -s ncpa_listener
command[check_node_exporter]=/usr/local/nagios/libexec/check_service.sh -s node_exporter

#command[check_eth]=/usr/local/nagios/libexec/check_eth -i eth0 -w 2M Bps -c 10M Bps
command[check_eth]=/usr/local/nagios/libexec/check_eth -i eth0 -w 1024K Bps -c 2048K Bps

EOF
		# fi
	chown nagios:nagios /usr/local/nagios/etc/nrpe.cfg
	chmod 644 /usr/local/nagios/etc/nrpe.cfg
	fi
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Client Copy Libexec
function customize_nagios_client_copy_libexec {

	# check_ssl_certificate
	yum -y install nagios-plugins-perl >/dev/null 2>&1
	# yum -y install libcrypt-ssleay-perl
	# yum -y install libcrypt-x509-perl

	print_info "Step 2: 拷贝libexec 到本地"
	if [[ -d "${GITHUB_REPO_TOOLBOX}/Nagios/Libexec" ]] ; then
		cp -pf 	${GITHUB_REPO_TOOLBOX}/Nagios/Libexec/* /usr/local/nagios/libexec/
		cp -pf 	${GITHUB_REPO_TOOLBOX}/Nagios/Libexec/*.* /usr/local/nagios/libexec/
		chmod 755 /usr/local/nagios/libexec/*
		chmod 755 /usr/local/nagios/libexec/*.*
	else
		print_error "请先Git同步toolbox到本地，再进行设置！"
		print_error "Plan B: wget 文件到Libexec"
		
#		rm -f /usr/local/nagios/libexec/check_cpu_stats.sh
#		rm -f /usr/local/nagios/libexec/check_kernel
#		rm -f /usr/local/nagios/libexec/check_mem.pl
#		rm -f /usr/local/nagios/libexec/check_mem
#		rm -f /usr/local/nagios/libexec/check_service.sh
#		rm -f /usr/local/nagios/libexec/check_ssl_certificate
#		rm -f /usr/local/nagios/libexec/check_netinterfaces
#		rm -f /usr/local/nagios/libexec/check_eth

		wget -c -q -P /tmp/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec.zip"	
		unzip -o /tmp/Libexec.zip -d /tmp/ >/dev/null
		mv -f /tmp/Libexec/* /usr/local/nagios/libexec/
		
		rm -f /tmp/Libexec.zip
		rm -rf /tmp/Libexec/ 
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_cpu_stats.sh"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_kernel"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_mem.pl"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_mem"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_service.sh"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_ssl_certificate"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_ssl_cert_expiry"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_netinterfaces"
#		wget -c -q -P /usr/local/nagios/libexec/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/Libexec/check_eth"

		chmod 755 /usr/local/nagios/libexec/*
		chmod 755 /usr/local/nagios/libexec/*.*
	fi
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Client Restart
function customize_nagios_client_restart {
	print_info "重启NRPE服务"
	systemctl restart nrpe
	# systemctl status nrpe
}
#-----------------------------------------------------------------------------#
# 定制 Nagios Client
function customize_nagios_client {
	print_start "定制 Nagios Client "

	customize_nagios_client_nrpe_cfg
	customize_nagios_client_copy_libexec
	customize_nagios_client_restart

	print_complete "定制 Nagios Client "
}
#-----------------------------------------------------------------------------#
# 激活 Nagios 黑暗模式 
function enable_nagios_dark_mode {
	print_start "激活 Nagios 黑暗模式 "
	print_info "Step 1: 备份源文件 "
	if [[ ! -d "/etc/fuckGFW/nagios/stylesheets" ]] ; then
		cp -rpf /usr/local/nagios/share/stylesheets /etc/fuckGFW/nagios/
		cp -pf /usr/local/nagios/share/index.php /etc/fuckGFW/nagios/index.php
	else
		print_error "备份已存在，无需重复备份！！！ "
	fi
	print_info "Step 2: 复制黑暗模式 "
	rm -rf /usr/local/nagios/share/stylesheets
	rm -f /usr/local/nagios/share/index.php

	if [[ -d "/root/git/toolbox/Nagios/nagios4-dark-theme-master/stylesheets" ]] ; then
		cp -rpf /root/git/toolbox/Nagios/nagios4-dark-theme-master/stylesheets /usr/local/nagios/share/
		cp -pf /root/git/toolbox/Nagios/nagios4-dark-theme-master/index.php /usr/local/nagios/share/index.php
	else
		print_error "Git未安装或未同步，执行Plan B"
		mkdir -p /usr/local/nagios/share/stylesheets
		wget -c -q -P /usr/local/nagios/share/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/nagios4-dark-theme-master/stylesheets.zip"
		wget -c -q -P /usr/local/nagios/share/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Nagios/nagios4-dark-theme-master/index.php"
		unzip -o /usr/local/nagios/share/stylesheets.zip -d /usr/local/nagios/share/ >/dev/null
		rm -f /usr/local/nagios/share/stylesheets.zip
	fi
	chown nagios:nagios /usr/local/nagios/share/index.php
	chown -R nagios:nagios /usr/local/nagios/share/stylesheets

	print_info "Step 3: 重启 Nagios "
	systemctl restart nagios
	# systemctl status nagios
	print_complete "激活 Nagios 黑暗模式 "
}
#-----------------------------------------------------------------------------#
# 恢复 Nagios 普通模式 
function enable_nagios_normal_mode {
	print_start "恢复 Nagios 普通模式 "
	print_info "Step 1: 复制普通模式 "
	rm -rf /usr/local/nagios/share/stylesheets
	rm -f /usr/local/nagios/share/index.php
	cp -rpf /etc/fuckGFW/nagios/stylesheets /usr/local/nagios/share/
	cp -pf /etc/fuckGFW/nagios/index.php /usr/local/nagios/share/index.php
	print_info "Step 2: 重启 Nagios "
	systemctl restart nagios
	# systemctl status nagios
	print_complete "恢复 Nagios 普通模式 "
}
#-----------------------------------------------------------------------------#
# 激活 apache httpd SSL
function enable_apache_httpd_ssl {
	print_start "激活 apache httpd SSL - Port: 8443"
	if [[ -f "/etc/httpd/conf.d/ssl.conf" ]]; then
		print_error "apache httpd SSL已经设置，无需重复操作！"
	else
		print_info "Step 1: 安装ssl认证模块 "
		yum -y install mod_ssl >/dev/null 2>&1
		print_info "Step 2: 编辑 /etc/httpd/conf.d/ssl.conf"
		cat <<EOF >/etc/httpd/conf.d/ssl.conf
Listen 8443 https

SSLPassPhraseDialog exec:/usr/libexec/httpd-ssl-pass-dialog
SSLSessionCache         shmcb:/run/httpd/sslcache(512000)
SSLSessionCacheTimeout  300
SSLCryptoDevice builtin

<VirtualHost _default_:8443>

ErrorLog logs/ssl_error_log
TransferLog logs/ssl_access_log
LogLevel warn

SSLEngine on

#SSLProtocol all -SSLv3
#SSLProxyProtocol all -SSLv3

SSLHonorCipherOrder on

SSLCipherSuite PROFILE=SYSTEM
SSLProxyCipherSuite PROFILE=SYSTEM

SSLCertificateFile /etc/fuckGFW/tls/${currentHost}.cer
SSLCertificateKeyFile /etc/fuckGFW/tls/${currentHost}.key
SSLCertificateChainFile /etc/fuckGFW/tls/fullchain.cer
SSLCACertificateFile /etc/fuckGFW/tls/ca.cer

<FilesMatch "\.(cgi|shtml|phtml|php)$">
    SSLOptions +StdEnvVars
</FilesMatch>
<Directory "/var/www/cgi-bin">
    SSLOptions +StdEnvVars
</Directory>

BrowserMatch "MSIE [2-5]" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

CustomLog logs/ssl_request_log \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"

</VirtualHost>
EOF
		print_info "Step 3: 编辑 /etc/httpd/conf/httpd.conf "
		if cat /etc/httpd/conf/httpd.conf | grep "# 2021 July 21st" ; then
			print_error "已经设置跳转https，无需重复！"
		else
			cat <<EOF >>/etc/httpd/conf/httpd.conf
# 2021 July 21st
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
EOF
		fi
		print_info "Step 4: 重新启动 httpd.service "
		#重启http服务
		systemctl restart httpd.service
		#查看状态
		# systemctl status httpd.service
		print_info "Nagio 访问地址 https://${currentHost}:8443/nagios"
		print_info "Nagio 用户名：nagiosadmin"
		print_info "Nagio 密码：xxxxxx"
	fi
	print_complete "激活 apache httpd SSL - Port: 8443 "
}
#-----------------------------------------------------------------------------#
# 安装 nagios server
function install_nagios_server {
	print_start "安装 Nagios Core"
	nagios_status_running=$(systemctl status nagios | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
	if [ "$nagios_status_running" == "running" ]  
        then  
            print_info "Nagios 服务正在运行！" 
			print_error "无需重新安装！"
		else
	# Security-Enhanced Linux
	# This guide is based on SELinux being disabled or in permissive mode. 
	# Steps to do this are as follows.
	print_info "Step 1: Security-Enhanced Linux"
	sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
	# print_complete "Step 1: Security-Enhanced Linux"

	# Prerequisites
	# Perform these steps to install the pre-requisite packages.
	# httpd -> Apache Web Server
	print_info "Step 2: Prerequisites"
	yum install -y gcc glibc glibc-common perl httpd php wget gd gd-devel
	yum update -y
	print_complete "Step 2: Prerequisites"

	# Downloading the Source
	print_info "Step 3: Downloading the Source"
	print_info "nagios-4.4.6."
	cd /tmp
	wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.6/nagios-4.4.6.tar.gz
	tar xzf nagioscore.tar.gz
	print_complete "Step 3: Downloading the Source"
	
	# Compile
	print_info "Step 4: Compile"
	cd /tmp/nagios-4.4.6/
	./configure
	make all
	print_complete "Step 4: Compile"

	# Create User And Group
	# This creates the nagios user and group. 
	# The apache user is also added to the nagios group.
	print_info "Step 5: Create User And Group"
	make install-groups-users
	usermod -a -G nagios apache
	print_complete "Step 5: Create User And Group"

	# Install Binaries
	# This step installs the binary files, CGIs, and HTML files.
	print_info "Step 6: Install Binaries"
	make install
	print_complete "Step 6: Install Binaries"

	# Install Service / Daemon
	# This installs the service or daemon files and also configures them to start on boot. 
	# The Apache httpd service is also configured at this point.
	print_info "Step 7: Install Service / Daemon"
	make install-daemoninit
	systemctl enable httpd.service
	print_complete "Step 7: Install Service / Daemon"

	# Install Command Mode
	# This installs and configures the external command file.
	print_info "Step 8: Install Command Mode"
	make install-commandmode
	print_complete "Step 8: Install Command Mode"

	# Install Configuration Files
	# This installs the *SAMPLE* configuration files. 
	# These are required as Nagios needs some configuration files to allow it to start.
	print_info "Step 9: Install Configuration Files"
	make install-config
	print_complete "Step 9: Install Configuration Files"

	# Install Apache Config Files
	# This installs the Apache web server configuration files. 
	# Also configure Apache settings if required.
	print_info "Step 10: Install Apache Config Files"
	make install-webconf
	print_complete "Step 10: Install Apache Config Files"

	# Configure Firewall
	# You need to allow port 80 inbound traffic on the local firewall 
	# so you can reach the Nagios Core web interface.
	print_info "Step 11: Configure Firewall"
	firewall-cmd --zone=public --add-port=8080/tcp
	firewall-cmd --zone=public --add-port=8080/tcp --permanent
	print_complete "Step 11: Configure Firewall"

	# Create nagiosadmin User Account
	# You'll need to create an Apache user account to be able to log into Nagios.
	# The following command will create a user account called nagiosadmin and 
	# you will be prompted to provide a password for the account.
	print_info "Step 12: Create nagiosadmin User Account"
	htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
	print_complete "Step 12: Create nagiosadmin User Account"

	# Start Apache Web Server
	print_info "Step 13: Start Apache Web Server"
	systemctl start httpd.service
	print_complete "Step 13: Start Apache Web Server"

	# Start Service / Daemon
	# This command starts Nagios Core.
	print_info "Step 14: Start Service / Daemon for Nagios Core"
	systemctl start nagios.service
	print_complete "Step 14: Start Service / Daemon for Nagios Core"

	# Test Nagios
	# Nagios is now running, to confirm this you need to log into the Nagios Web Interface.
	# Point your web browser to the ip address or FQDN of your Nagios Core server, 
	# for example:
	# http://10.25.5.143/nagios
	# http://core-013.domain.local/nagios
	fi
	print_complete "安装 Nagios Core"
}
#-----------------------------------------------------------------------------#
# 安装 nagios plugins
function install_nagios_plugins {
	print_start "安装 Nagios Plugins 2.3.3"
	if [[ -f "/usr/local/nagios/libexec/check_cpu_stats.sh" ]]; then
        print_info "Nagios Plugins 服务正在运行！" 
		print_error "无需重复安装！"
	else
	# 2021-April-06 [Initial Version] - Shell Script for Nagios Plugins installing
	# Nagios Plugins - Installing Nagios Plugins From Source

	# Security-Enhanced Linux
	# This guide is based on SELinux being disabled or in permissive mode. 
	# Steps to do this are as follows.
	print_info "Step 1: Security-Enhanced Linux"
	sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
	# print_complete "Step 1: Security-Enhanced Linux"

	# Prerequisites
	# Perform these steps to install the pre-requisite packages.
	print_info "Step 2: Prerequisites"
	sleep 2
	yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
	yum --enablerepo=PowerTools,epel install perl-Net-SNMP
	yum -y install sysstat
	print_complete "Step 2: Prerequisites"

	# Downloading the Source
	print_info "Step 3: 下载Nagios Plugins 2.2.3 到tmp文件夹"
	cd /tmp
	wget --no-check-certificate https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.3.3/nagios-plugins-2.3.3.tar.gz
	tar xzf nagios-plugins-2.3.3.tar.gz
	cd nagios-plugins-2.3.3
	print_complete "Step 3: 下载Nagios Plugins 2.2.3 到tmp文件夹"

	# Nagios Plugins Installation
	print_info "Step 4: 安装nagios plugins, 并重新启动nrpe服务"
	./tools/setup
	./configure
	make
	make install
	systemctl restart nrpe
	print_complete "Step 4: 安装nagios plugins, 并重新启动nrpe服务"
	fi
	print_complete "安装 Nagios Plugins 2.3.3"
}
#-----------------------------------------------------------------------------#
# 安装 nagios nrpe
function install_nagios_nrpe {
	print_start "安装 Nagios NRPE"
	# NRPE - Nagios Remote Plugin Executor
	nrpe_status_running=$(systemctl status nrpe | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
	if [ "$nrpe_status_running" == "running" ]  
        then  
            print_info "NRPE 服务正在运行！" 
			print_error "无需重新安装！"
		else
	#*** Configuration summary for nrpe 4.0.3 2020-04-28 ***:
	#
	# General Options:
	# -------------------------
	# NRPE port:    5666
	# NRPE user:    nagios
	# NRPE group:   nagios
	# Nagios user:  nagios
	# Nagios group: nagios

	#Security-Enhanced Linux
	#This guide is based on SELinux being disabled or in permissive mode. Steps to do this are as follows.
	print_info "Step 1: SELINUX Disable"
	sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
	# print_complete "Step 1: SELINUX Disable"

	#Prerequisites
	#Perform these steps to install the pre-requisite packages.
	print_info "Step 2: Prerequisites"
	yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
	# yum --enablerepo=PowerTools,epel install perl-Net-SNMP
	print_complete "Step 2: Prerequisites"

	#Download NRPE package
	#下载NRPE包
	print_info "Step 3: 下载nrpe-4.0.3到tmp文件夹"
	cd /tmp
	wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.0.3/nrpe-4.0.3.tar.gz
	tar xzf nrpe-4.0.3.tar.gz
	cd nrpe-4.0.3
	print_complete "Step 3: 下载nrpe-4.0.3到tmp文件夹"

	#NPRE Installation
	print_info "Step 4: 安装nrpe，设置用户和用户组、并初始化和启动nrpe服务"
	./configure
	make all
	make install-groups-users
	make install
	make install-config
	make install-init
	systemctl enable nrpe 
	systemctl start nrpe
	print_complete "Step 4: 安装nrpe，设置用户和用户组、并初始化和启动nrpe服务"

	#firewall enable port 5666
	#===== RHEL 7/8 | CentOS 7/8 | Oracle Linux 7/8 =====
	print_info "Step 5: 设置防火墙开启端口 5666"
	firewall-cmd --zone=public --add-port=5666/tcp
	firewall-cmd --zone=public --add-port=5666/tcp --permanent
	print_complete "Step 5: 设置防火墙开启端口 5666"
	fi
	print_complete "安装 Nagios NRPE"
}
#-----------------------------------------------------------------------------#
# 安装 nagios ncpa
function install_nagios_ncpa {
	print_start "安装 Nagios NCPA "
	ncpa_status_running=$(systemctl status ncpa_listener.service | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
	if [ "$ncpa_status_running" == "running" ]  
        then  
            print_info "NCPA 服务正在运行！" 
			print_error "无需重新安装！"
		else

	# Nagios Cross-Platform Agent
	print_info "Installing the Nagios Repository"
	rpm -Uvh https://repo.nagios.com/nagios/8/nagios-repo-8-1.el8.noarch.rpm

	print_info "Installing NCPA"
	yum install ncpa -y

	print_info "展示 NCPA 配置文件 /usr/local/ncpa/etc/ncpa.cfg"
	cat /usr/local/ncpa/etc/ncpa.cfg
	
	sudo ln -s /usr/bin/python3 /usr/bin/python >/dev/null 2>&1
	print_info "访问 https://${currentHost}:5693/"

	fi
	print_complete "安装 Nagios NCPA "
}
#-----------------------------------------------------------------------------#
# 卸载 nagios ncpa
function uninstall_nagios_ncpa {
	# Nagios Cross-Platform Agent
	print_start "卸载 Nagios NCPA "

	print_info "Uninstalling NCPA"
	yum -y remove ncpa

	print_complete "卸载 Nagios NCPA "
}
#-----------------------------------------------------------------------------#
# 安装 & 运行 Prometheus container - Port: 9090 
function install_exec_prometheus {

	docker run -d \
	--name="prometheus-standalone" \
    -p 9090:9090 \
    -v /etc/fuckGFW/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus:latest

}
#-----------------------------------------------------------------------------#
# 安装 & 运行 Node Exporter container - Port: 9100 
function install_exec_node_exporter {

	docker run -d \
	--name="node-exporter" \
	--net="host" \
	--pid="host" \
	-v "/:/host:ro,rslave" \
	quay.io/prometheus/node-exporter:latest \
	--path.rootfs=/host
  
}
#-----------------------------------------------------------------------------#
# 安装 Node Exporter linux 版本
function install_exec_node_exporter_linux {
	print_start "安装 Node Exporter linux 版本 "
	if [[ -f "/usr/sbin/node_exporter" ]]; then
		print_error "Node Exporter已经安装，无需重复操作！"
	else
		print_info "Step 1: Installing the repository "
		curl -Lo /etc/yum.repos.d/_copr_ibotty-prometheus-exporters.repo https://copr.fedorainfracloud.org/coprs/ibotty/prometheus-exporters/repo/epel-8/ibotty-prometheus-exporters-epel-8.repo

		print_info "Step 2: 安装 node_exporter"
		yum -y install node_exporter

		print_info "Step 3: Enable and restart node_exporter service"
		
		print_info "Step 3-1: 重新加载daemon-reload"
		systemctl daemon-reload
		
		print_info "Step 3-2: Enable node_exporter服务"
		systemctl enable node_exporter
		
		print_info "Step 3-3: Restart node_exporter服务"
		systemctl restart node_exporter
	fi
	print_complete "安装 Node Exporter linux 版本 "
}
#-----------------------------------------------------------------------------#
# 卸载 Node Exporter linux 版本
function uninstall_exec_node_exporter_linux {
	print_start "卸载 Node Exporter linux 版本 "
	yum -y remove node_exporter >/dev/null 2>&1
	print_complete "卸载 Node Exporter linux 版本 "
}
#-----------------------------------------------------------------------------#
# 安装 & 运行 Grafana container - Port: 3000 
function install_exec_grafana {
	
	docker run -d \
	-p 3000:3000 \
	--name="grafana-standalone" \
	-e "TZ: Asia/Shanghai" \
    -e "GF_SERVER_PROTOCOL: http" \
	-e "GF_SERVER_HTTP_PORT: 3000" \
	-e "GF_SERVER_DOMAIN: ${currentHost}" \
	-e "GF_SERVER_SERVE_FROM_SUB_PATH: "true"" \
	-e "GF_SECURITY_ADMIN_USER: root" \
	-e "GF_SECURITY_ADMIN_PASSWORD: "abc123abc"" \
	-e "GF_SERVER_ENABLE_GZIP: 'true'" \
	-e "GF_USERS_ALLOW_SIGN_UP: 'true'" \
	-e "GF_USERS_VIEWERS_CAN_EDIT: 'true'" \
	-e "GF_AUTH_ANONYMOUS_ENABLED: 'true'" \
	-e "GF_AUTH_ANONYMOUS_ORG_NAME: Main Org." \
	-e "GF_AUTH_ANONYMOUS_ORG_ROLE: Viewer" \
	-e "GF_ANALYTICS_REPORTING_ENABLED: 'false'" \
	-e "GF_ANALYTICS_CHECK_FOR_UPDATES: 'false'" \
	grafana/grafana:latest

}
#-----------------------------------------------------------------------------#
# 停止 & 删除 Prometheus
function stop_remove_prometheus {
	docker container stop prometheus-standalone
	docker container rm -f prometheus-standalone
}
#-----------------------------------------------------------------------------#
# 停止 & 删除 Node Exporter container
function stop_remove_node_exporter {
	docker container stop node-exporter
	docker container rm -f node-exporter
}
#-----------------------------------------------------------------------------#
# 停止 & 删除 Grafana container 
function stop_remove_grafana {
	docker container stop grafana-standalone
	docker container rm -f grafana-standalone
}
#-----------------------------------------------------------------------------#
# 安装其他软件菜单
function install_other_software_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "----------------------------安装菜单------------------------------"
	echoContent yellow "1.安装 Node Exporter 单机版 - Port: 9100 "
	echoContent yellow "2.安装 nginx 单机版         - port: 7080 "
	echoContent yellow "3.安装 httpd 单机版         - port: 8080 & port: 8443 "
	echoContent skyBlue "----------------------------卸载菜单------------------------------"
	echoContent yellow "4.卸载 Node Exporter 单机版 - Port: 9100 "
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	1)
		install_exec_node_exporter_linux
		;;
	2)
		install_nginx
		;;
	3)
		install_apache_httpd
		enable_apache_httpd_ssl
		;;
	4)
		uninstall_exec_node_exporter_linux
		;;
	*)
		print_error "请输入正确的数字"
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# Grafana 菜单
function grafana_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "----------------------------安装菜单------------------------------"
	echoContent yellow "1.安装 & 运行 Prometheus container - Port: 9090 "
	echoContent yellow "2.安装 & 运行 Node Exporter container - Port: 9100 "
	echoContent yellow "3.安装 & 运行 Grafana container - Port: 3000 "
	echoContent skyBlue "----------------------------配置菜单------------------------------"
	echoContent yellow "4.停止 & 删除 Prometheus "
	echoContent yellow "5.停止 & 删除 Node Exporter container "
	echoContent yellow "6.停止 & 删除 Grafana container "
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in

	1)
		install_exec_prometheus
		;;
	2)
		install_exec_node_exporter
		;;
	3)
		install_exec_grafana
		;;
	4)
		stop_remove_prometheus
		sleep 1
		grafana_menu
		;;
	5)
		stop_remove_node_exporter
		sleep 1
		grafana_menu
		;;
	6)
		stop_remove_grafana
		sleep 1
		grafana_menu
		;;
	*)
		print_error "请输入正确的数字"
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# webmin 安装菜单
function webmin_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "----------------------------主机管理------------------------------"
	echoContent yellow "0.安装 全部程序"
	echoContent yellow "1.安装 webmin "
	echoContent yellow "2.激活 webmin SSL "
	echoContent yellow "3.修改 webmin port: 9999 "
	echoContent yellow "4.重启 webmin service "
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	0)
		install_webmin
		init_webmin_ssl
		init_webmin_port_9999
		restart_webmin_service
		;;
	1)
		install_webmin
		;;
	2)
		init_webmin_ssl
		;;
	3)
		init_webmin_port_9999
		;;
	4)
		restart_webmin_service
		;;
	*)
		print_error "请输入正确的数字"
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# Nagios 安装菜单
function nagios_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "----------------------------安装菜单------------------------------"
	echoContent yellow "0.安装 全部软件 "	
	echoContent yellow "1.安装 httpd - port: 8080 & port: 8443 "
	echoContent yellow "2.安装 nagios server "
	echoContent yellow "3.安装 nagios nrpe "
	echoContent yellow "4.安装 nagios ncpa "
	echoContent yellow "5.安装 nagios plugins "
	echoContent skyBlue "----------------------------配置菜单------------------------------"
	echoContent yellow "6.定制 nagios server "
	echoContent yellow "7.定制 nagios client "
	echoContent skyBlue "----------------------------主题选择------------------------------"
	echoContent yellow "8.激活 nagios server dark mode "
	echoContent yellow "9.激活 nagios server normal mode "
	echoContent skyBlue "----------------------------选装菜单------------------------------"
	echoContent yellow "10.展示 nagios server 配置文件 "
	echoContent yellow "11.展示 nagios client 配置文件 "
	echoContent yellow "12.清除 nagios myservers 文件夹 "
	echoContent yellow "13.卸载 nagios ncpa "
	echoContent skyBlue "----------------------------测试配置------------------------------"
	echoContent yellow "00.测试 nagios server 配置文件 "
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	0)
		install_apache_httpd
		enable_apache_httpd_ssl
		install_nagios_server
		install_nagios_nrpe
		install_nagios_ncpa
		install_nagios_plugins
		;;
	1)
		install_apache_httpd
		enable_apache_httpd_ssl
		;;
	2)
		install_nagios_server
		;;
	3)
		install_nagios_nrpe
		;;
	4)
		install_nagios_ncpa
		;;
	5)
		install_nagios_plugins
		;;
	6)
		customize_nagios_server
		;;
	7)
		customize_nagios_client
		;;
	8)
		enable_nagios_dark_mode
		;;
	9)
		enable_nagios_normal_mode
		;;
	10)
		cat /usr/local/nagios/etc/nagios.cfg
		;;
	11)
		cat /usr/local/nagios/etc/nrpe.cfg
		;;
	12)
		rm -rf /usr/local/nagios/etc/objects/myservers
		nagios_menu
		;;
	13)
		uninstall_nagios_ncpa
		;;
	00)
		/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
		;;
	*)
		print_error "请输入正确的数字"
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 科学上网菜单
function kxsw_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "--------------------------科学上网菜单----------------------------"
	echoContent yellow "1.安装 v2ray-agent | 快捷方式 [vasma]"
	echoContent yellow "2.安装 xray-OneKey"
	echoContent yellow "3.安装 BBR 拥塞控制算法加速 [提升性能明显，一定要安装！！！]"
	echoContent yellow "4.安装 v2-ui | 快捷方式 [v2-ui]"
	echoContent yellow "5.安装 x-ui  | 快捷方式 [x-ui]"
	echoContent yellow "6.安装 xray 单机"
	echoContent yellow "7.更新 xray 单机"
	echoContent red "=================================================================="
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	1)
		install_v2ray_agent
		;;
	2)
		install_xray_onekey
		;;
	3)
		install_bbr
		;;
	4)
		install_v2_ui
		;;
	5)
		install_x_ui
		;;
	6)		
		install_standalone_xray
		;;
	7)
		checkCPUVendor
		update_Xray
		;;
	*)
		print_error "请输入正确的数字"
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 生成配置文件&Log文件菜单
function generate_conf_log_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "--------------------------生成配置文件----------------------------"
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
	echoContent skyBlue "--------------------------生成日志文件----------------------------"
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
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 日志菜单
function log_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "--------------------------查看错误日志----------------------------"
	echoContent yellow "1.show error.log [Nginx] "
	echoContent yellow "2.show error.log [Trojan-go]"
	echoContent yellow "3.show error.log [v2ray]"
	echoContent yellow "4.show error.log [vxray]"
	echoContent skyBlue "--------------------------查看访问日志----------------------------"
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
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 配置菜单
function conf_menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "--------------------------查看配置文件----------------------------"
	echoContent yellow "1.show docker-compose.yml"
	echoContent yellow "2.show nginx 配置文件"
	echoContent yellow "3.show trojan-go 配置文件"
	echoContent yellow "4.show v2ray 配置文件"
	echoContent yellow "5.show xray 配置文件"
	echoContent yellow "6.show prometheus 配置文件"
	echoContent yellow "7.show grafana 配置文件"
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
	6)
		show_prometheus_conf
		;;
	7)
		show_grafana_ini
		;;
	*)
		print_error "请输入正确的数字"
		sleep 1
		menu
		;;
	esac
}
#-----------------------------------------------------------------------------#
# 主菜单
function menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool：\c"
	echoContent white "${SmartToolVersion}"
	echoContent green "Github：\c"
	echoContent white "https://github.com/linfengzhong/toolbox"
	echoContent green "logserver：\c"
	echoContent white "https://github.com/linfengzhong/logserver"
	echoContent green "初始化服务器、安装Docker、执行容器、科学上网 on \c" 
	echoContent white "${currentHost}"
	echoContent green "当前主机外部IP地址： \c" 
	echoContent white "${currentIP}"	
	echoContent green "当前UUID： \c" 
	echoContent white "${currentUUID}"
	echoContent green "当前系统Linux版本 : \c" 
	checkSystem
	echoContent red "=================================================================="
	echoContent skyBlue "--------------------------安装基础软件------------------------------"
	echoContent yellow "10.安装 全部程序"
	echoContent yellow "11.安装 prerequisite"
	echoContent yellow "12.安装 acme.sh"
	echoContent yellow "13.安装 bpytop"
	echoContent skyBlue "---------------------------版本控制-------------------------------"  
	echoContent yellow "20.git one key"
	echoContent yellow "21.git clone | 22.git pull | 23.git push"
	echoContent yellow "24.更新日志、配置文件、动态数据到GitHub"
	echoContent yellow "25.安装 git"
	echoContent skyBlue "---------------------------容器相关-------------------------------"
	echoContent yellow "30.docker one key"
	echoContent yellow "42.docker one key - lite"
	echoContent yellow "31.docker-compose up ｜ 32.docker-compose down"
	echoContent yellow "33.docker status"
	echoContent skyBlue "------------------------------------------------------------------"
	echoContent yellow "34.generate conf & logs [Sub Menu]"
	echoContent yellow "35.show configs [Sub Menu]"
	echoContent yellow "36.show logs [Sub Menu]"
	echoContent yellow "37.show account"
	echoContent yellow "38.安装 docker CE & docker compose"
	echoContent yellow "39.卸载 docker CE & docker compose"
	echoContent skyBlue "---------------------------证书管理-------------------------------"
	echoContent yellow "40.CA one key | 41.generate CA "
	echoContent skyBlue "---------------------------脚本管理-------------------------------"
	echoContent yellow "0.更新脚本"
	echoContent yellow "1.科学上网工具 [Sub Menu]"
	echoContent yellow "2.Nagios监控  - port: 8443 [Sub Menu]"
	echoContent yellow "3.Grafana监控 - port: 3000 [Sub Menu]"
	echoContent yellow "4.Webmin管理  - port: 10000[Sub Menu]"
	echoContent yellow "5.安装其他 - port: 7080 / 8080 / 8443 [Sub Menu] "
	echoContent yellow "6.设置域名 | 7.设置时区：上海 ｜ 8.设置随机UUID "
	echoContent yellow "9.状态监控 bpytop "
	echoContent red "=================================================================="
	mkdirTools
	aliasInstall
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	0)
		updateSmartTool
		sleep 1
		st
		;;
	1)
		kxsw_menu
		;;
	2)
		nagios_menu
		;;
	3)
		grafana_menu
		;;
	4)
		webmin_menu
		;;
	5)
		install_other_software_menu
		;;
	6)
		clear_myHostDomain
		set_current_host_domain
		;;
	7)
		set_timezone
		sleep 1
		st
		;;
	8)
		clear_currentUUID
		set_current_uuid
		sleep 1
		st
		;;
	9)
		execBpytop
		;;
	10)
		install_prerequisite
		install_acme
		install_bpytop
		sleep 2
		st
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
	20)
		install_git
		git_init
		sleep 2
		st
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
	25)
		install_git
		;;
	30)
		print_error "Docker 映射端口 7080 & 7443"
		install_docker
		install_docker_compose
		generate_docker_compose_yml
		docker_compose_down
		github_pull_toolbox
		github_pull_logserver
		generate_docker_compose_yml
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
		docker_compose_up
		;;
	31)
		docker_compose_up
		;;
	32)
		docker_compose_down
		;;
	33)
		docker_images
		docker_container_ps
		;;
	34)
		generate_conf_log_menu
		;;
	35)
		conf_menu
		;;
	36)
		log_menu
		;;
	37)
		generate_vmess_trojan_account
		;;
	38)
		install_docker
		install_docker_compose
		;;
	39)
		uninstall_docker_and_docker_compose
		;;
	42)
		install_docker
		install_docker_compose
		generate_docker_compose_yml_lite
		docker_compose_down
		docker_compose_up
		;;
	40)
		install_acme
		renewalTLS
		sleep 3
		st
		;;
	41)
		generate_ca
		checkTLStatus "${currentHost}"
		sleep 3
		st
		;;
	*)
		print_error "请输入正确的数字"
#		menu "$@"
		;;
	esac
}

# 检查指定端口是否开启
function checkPortStatus()
{
	status=`nmap -sS 127.0.0.1 -p $1 | grep open | awk '{print $2}'`
	if [ "$status" != "open" ];
		then
			return 0;
        else
			return 1;
	fi
}
# 判断进程是否再运行
function check_procs_status() {
	PROC_NAME=$1  
	ProcNumber=`ps -ef |grep -w $PROC_NAME|grep -v grep|wc -l`  
	if [ $ProcNumber -le 0 ];then  
	result=0  
	else  
	result=1   
	fi 
}

SmartToolVersion=v0.349
cleanScreen
inital_smart_tool $1
set_current_host_domain
cronRenewTLS
menu
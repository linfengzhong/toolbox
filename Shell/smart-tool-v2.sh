#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-25 [Add new functions] - Stop/Start docker-compose
#-----------------------------------------------------------------------------#
# 检查系统
checkSystem() {
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
#-----------------------------------------------------------------------------#
# 输出带颜色内容 字体颜色配置
echoContent() {
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
checkTLStatus() {

	if [[ -n "$1" ]]; then
		if [[ -d "$HOME/.acme.sh/$1_ecc" ]] && [[ -f "$HOME/.acme.sh/$1_ecc/$1.key" ]] && [[ -f "$HOME/.acme.sh/$1_ecc/$1.cer" ]]; then
			modifyTime=$(stat $HOME/.acme.sh/$1_ecc/$1.key | sed -n '7,6p' | awk '{print $2" "$3" "$4" "$5}')

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
installCronTLS() {
	echoContent skyBlue "\n进度 $1/${totalProgress} : 添加定时维护证书"
	crontab -l >/etc/v2ray-agent/backup_crontab.cron
	sed '/v2ray-agent/d;/acme.sh/d' /etc/v2ray-agent/backup_crontab.cron >/etc/v2ray-agent/backup_crontab.cron
	echo "30 1 * * * /bin/bash /etc/v2ray-agent/install.sh RenewTLS" >>/etc/v2ray-agent/backup_crontab.cron
	crontab /etc/v2ray-agent/backup_crontab.cron
	echoContent green "\n ---> 添加定时维护证书成功"
}

#-----------------------------------------------------------------------------#
# 调用
#echoContent green " ---> 检测到证书"
#		checkTLStatus "${tlsDomain}"
#-----------------------------------------------------------------------------#
# 脚本快捷方式
aliasInstall() {
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
updateSmartTool() {
	echoContent skyBlue "\n 更新Smart tool 脚本"
	rm -rf /etc/smart-tool/smart-tool-v2.sh
	if wget --help | grep -q show-progress; then
		wget -c -q --show-progress -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v2.sh"
	else
		wget -c -q -P /etc/smart-tool/ -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v2.sh"
	fi

	sudo chmod 700 /etc/smart-tool/smart-tool-v2.sh
	local version=$(cat /etc/smart-tool/smart-tool-v2.sh | grep '当前版本：v' | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')

	echoContent green "\n ---> 更新完毕"
	echoContent yellow " ---> 请手动执行[st]打开脚本"
	echoContent green " ---> 当前版本:${version}\n"
	echoContent yellow "如更新不成功，请手动执行下面命令\n"
	echoContent skyBlue "wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/Shell/smart-tool-v2.sh" && chmod 700 /root/smart-tool-v2.sh && /root/smart-tool-v2.sh"
	echo
	exit 0
}
#-----------------------------------------------------------------------------#
# 初始化安装目录
mkdirTools() {
	mkdir -p /etc/smart-tool
}
#-----------------------------------------------------------------------------#
# 主菜单
menu() {
	cd "$HOME" || exit
	echoContent red "\n=============================================================="
	echoContent green "SmartTool：v0.01"
	echoContent green "当前版本：v0.02"
	echoContent green "Github：https://github.com/linfengzhong/toolbox"
	echoContent green "初始化服务器、安装Docker、执行容器\c"
	echoContent red "\n=============================================================="
	echoContent yellow "2.任意组合安装"
	echoContent skyBlue "-------------------------工具管理-----------------------------"
	echoContent yellow "3.账号管理"
	echoContent yellow "4.更换伪装站"
	echoContent yellow "5.更新证书"
	echoContent yellow "6.更换CDN节点"
	echoContent yellow "7.IPv6分流"
	echoContent yellow "8.流媒体工具"
	echoContent yellow "9.添加新端口"
	echoContent skyBlue "-------------------------版本管理-----------------------------"
	echoContent yellow "10.core管理"
	echoContent yellow "11.更新Trojan-Go"
	echoContent yellow "12.更新脚本"
	echoContent yellow "13.安装BBR、DD脚本"
	echoContent skyBlue "-------------------------脚本管理-----------------------------"
	echoContent yellow "14.查看日志"
	echoContent yellow "15.卸载脚本"
	echoContent red "=============================================================="
	mkdirTools
	aliasInstall
	read -r -p "请选择:" selectInstallType
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
		coreVersionManageMenu 1
		;;
	11)
		updateTrojanGo 1
		;;
	12)
		updateSmartTool 1
		;;
	13)
		bbrInstall
		;;
	14)
		checkLog 1
		;;
	15)
		unInstall 1
		;;
	esac
}

initVar $1
checkSystem
#readInstallType
#readInstallProtocolType
#readConfigHostPathUUID
menu

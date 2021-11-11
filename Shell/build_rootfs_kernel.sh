#!/bin/sh
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-Oct-13 [Initial Version] - Build Debain rootfs & Kernel
#-----------------------------------------------------------------------------#
#================================== Debian ===================================#
#-----------------------------------------------------------------------------#
# 初始化全局变量
export LANG=en_US.UTF-8
function inital_tool() {
	#定义变量
	WORKDIR="/boot"
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
    mkdir -p /etc/smart-tool
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
# 脚本快捷方式
function aliasInstall() {
	if [[ -f "$HOME/st.sh" ]] && [[ -d "/etc/smart-tool" ]] && grep <$HOME/st.sh -q "Author: Linfeng Zhong (Fred)"; then
		mv "$HOME/st.sh" /etc/smart-tool/st.sh
		if [[ -d "/usr/bin/" ]] && [[ ! -f "/usr/bin/st" ]]; then
			ln -s /etc/smart-tool/st.sh /usr/bin/st
			chmod 700 /usr/bin/st
			rm -rf "$HOME/st.sh"
		elif [[ -d "/usr/sbin" ]] && [[ ! -f "/usr/sbin/st" ]]; then
			ln -s /etc/smart-tool/st.sh /usr/sbin/st
			chmod 700 /usr/sbin/st
			rm -rf "$HOME/st.sh"
		fi
	fi
	echoContent green "快捷方式创建成功，可执行[st]重新打开脚本"
}
function flash_pogoplug_pro_v3_128MB_NAND(){
    # 开始刷NAND
    print_start "PogoPlugPro V3 128MB flash bootloader"
    cd /boot
    print_info "Step 1 -> Erase 6 blocks on mtd0"
    /usr/sbin/flash_erase /dev/mtd0 0x0 6
    print_info "Step 2 -> Flash encoded spl stage1 to 0x0"
    /usr/sbin/nandwrite /dev/mtd0 /root/uboot.2015.10-tld-2.ox820.bodhi/uboot.spl.2013.10.ox820.850mhz.mtd0.img
    print_info "Step 3 -> Flash u-boot to 0x40000"
    /usr/sbin/nandwrite -s 262144 /dev/mtd0 /root/uboot.2015.10-tld-2.ox820.bodhi/uboot.2015.10-tld-2.ox820.mtd0.img
    print_info "Step 4 -> Erase 1 block starting 0x00100000"
    /usr/sbin/flash_erase /dev/mtd0 0x00100000 1
    print_info "Step 5 -> Flash uboot environment to 0x00100000"
    /usr/sbin/nandwrite -s 1048576 /dev/mtd0 /root/uboot.2015.10-tld-2.ox820.bodhi/uboot.2015.10-tld-2.ox820.environment.img
    sync
    sync
    sync
    print_complete "PogoPlugPro V3 128MB flash bootloader"
}
function build_Debian_4.14.180_rootfs() {
    print_start "Build Debian 4.14.180 rootfs"
    mkdir -p /media/sdb1
    mount /dev/sdb1 /media/sdb1
    cd /media/sdb1
    
    print_info "Step 1: 复制 rootfs tar file to target disk"
    cp -p /root/Debian-4.14.180-oxnas-tld-1-rootfs-bodhi.tar.bz2 .

    print_info "Step 2: 解压缩 Debian-4.14.180-oxnas-tld-1-rootfs-bodhi.tar.bz2"
    tar -xjf Debian-4.14.180-oxnas-tld-1-rootfs-bodhi.tar.bz2

    print_info "Step 3: 编辑 /media/sdb1/etc/fstab"
    sed -i 's!ext3!ext3!g' /media/sdb1/etc/fstab
    cat /media/sdb1/etc/fstab

    sync
    sync
    sync
    print_complete "Build Debian 4.14.180 rootfs"
}

function upgrade_kernel_to_5.4.101() {
    print_start "Upgrade Linux Kernel to 5.4.101"
    cd /boot
    print_info "Step 1: Extract the kernel in the archive"
    tar -xjf linux-5.4.101-oxnas-tld-1.bodhi.tar.bz2

    print_info "Step 2: Extract the tarball for the dtb files"
    tar -xjf linux-dtb-5.4.101-oxnas-tld-1.tar

    print_info "Step 3: Remove flash-kernel"
    apt-get remove flash-kernel

    print_info "Step 4: Install kernel with dpky"
    dpkg -i linux-image-5.4.101-oxnas-tld-1_1.0_armel.deb

    print_info "Step 5: Create uImage and uInitrd"
    mv uImage uImage.bak
    mv uInitrd uInitrd.bak
    mkimage -A arm -O linux -T kernel -C none -a 0x60008000 -e 0x60008000 -n Linux-5.4.101-oxnas-tld-1 -d vmlinuz-5.4.101-oxnas-tld-1 uImage
    mkimage -A arm -O linux -T ramdisk -C gzip -a 0x60000000 -e 0x60000000 -n initramfs-5.4.101-oxnas-tld-1  -d initrd.img-5.4.101-oxnas-tld-1 uInitrd

    sync
    sync
    sync
    print_complete "Upgrade Linux Kernel to 5.4.101"
}

function generate_ssh_key() {
    print_start "Generate SSH Key"
    cd /etc/ssh
    rm -f /etc/ssh/ssh_host*
    ssh-keygen -A

    apt-get update
    apt-get upgrade

    sync
    sync
    sync
    print_complete "Generate SSH Key"
}

function customize_uimage_environment() {
    print_start "Customize uImage environment"

    print_info "Step 1: Customize MAC, IP and Server IP addresses"
    fw_setenv ethaddr '00:01:02:03:11:09'
    fw_setenv ipaddr '192.168.1.9'
    fw_setenv serverip '192.168.1.66'

    print_info "Step 2: Enable Net Console"
    fw_setenv if_netconsole 'ping $serverip'
    fw_setenv start_netconsole 'setenv ncip $serverip; setenv bootdelay 10; setenv stdin nc; setenv stdout nc; setenv stderr nc; version;'
    fw_setenv preboot 'run if_netconsole start_netconsole'

    print_info "Step 3: Enable uEnt.ext function"
    fw_setenv uenv_import 'echo importing envs ...; env import -t 0x60500000  $filesize'

    sync
    sync
    sync
    print_complete "Customize uImage environment"
}
#-----------------------------------------------------------------------------#
# 主菜单
function menu() {
	clear
	cd "$HOME" || exit
	echoContent red "=================================================================="
	echoContent green "SmartTool for PogoplugPro v3"
	echoContent red "=================================================================="
	echoContent skyBlue "--------------------------安装基础软件------------------------------"
	echoContent yellow "0. 安装 定制固件到 PogoplugPro v3 128MB NAND (ArchLinux)"    
	echoContent yellow "1. 安装 Debian 4.14.180 rootfs     (Linux)"
	echoContent yellow "2. 安装 Linux Kernel 5.4.101 Oxnas (Debian 4.14.180)"
	echoContent yellow "3. 定制 SSH key    (Debian 10 Buster)"
	echoContent yellow "4. 定制 128MB NAND (Debian 10 Buster)"
	echoContent red "=================================================================="
	mkdirTools
	aliasInstall
	read -r -p "Please choose the function (请选择) : " selectInstallType
	case ${selectInstallType} in
	0)
        flash_pogoplug_pro_v3_128MB_NAND
		;;
	1)
        build_Debian_4.14.180_rootfs
		;;
	2)
		upgrade_kernel_to_5.4.101
		;;
	3)
		generate_ssh_key
		;;
	4)
		customize_uimage_environment
		;;
	*)
		print_error "请输入正确的数字"
#		menu "$@"
		;;
	esac
}
inital_tool
aliasInstall
menu
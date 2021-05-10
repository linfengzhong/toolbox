#!/usr/bin/env bash
#
#-rw------- (600)    只有拥有者有读写权限。
#-rw-r--r-- (644)    只有拥有者有读写权限；而属组用户和其他用户只有读权限。
#-rwx------ (700)    只有拥有者有读、写、执行权限。
#-rwxr-xr-x (755)    拥有者有读、写、执行权限；而属组用户和其他用户只有读、执行权限。
#-rwx--x--x (711)    拥有者有读、写、执行权限；而属组用户和其他用户只有执行权限。
#-rw-rw-rw- (666)    所有用户都有文件读、写权限。
#-rwxrwxrwx (777)    所有用户都有读、写、执行权限。
#检测配置文件是否 OK 的命令
#/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg 
#fonts color 字体颜色配置
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Green="\033[32m"

RedBG="\033[41;37m"
GreenBG="\033[42;37m"

Font="\033[0m"

#notification information
Info="${Green}[Message信息]${Font}"
OK="${Green}[OK正常]${Font}"
Error="${Red}[ERROR错误]${Font}"

#打印OK
function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

#打印错误
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}

#判定 成功 or 失败
judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 完成"
    sleep 1
  else
    print_error "$1 失败"
    exit 1
  fi
}
print_ok "开始配置Nagios Plugins -> libexec"
sleep 2
#切换root
sudo su
print_ok "切换root"

#切换到临时文件夹
cd /tmp
print_ok "切换到临时文件夹"
sleep 1
#从GitHub获取配置文件
wget --no-check-certificate https://github.com/linfengzhong/Nagios/archive/refs/tags/0.06.zip
print_ok "从GitHub获取配置文件"
sleep 1
#解压缩
unzip 0.06.zip
print_ok "解压缩配置文件"
sleep 1
#给文件赋予权限
chmod 777 /tmp/Nagios-0.06/Libexec/check_*
print_ok "给文件赋予权限 777"
sleep 1
#创建服务器配置文件夹
#mkdir /usr/local/nagios/etc/objects/myservers
#chmod 777 /usr/local/nagios/etc/objects/myservers
#chmod 777 /usr/local/nagios/etc/objects/myservers/*

#复制check程序到指定文件夹
\cp -p -f /tmp/Nagios-0.06/Libexec/check_* /usr/local/nagios/libexec
print_ok "复制check程序到指定文件夹:/usr/local/nagios/libexec"
sleep 1
#复制nrpe的主配置文件，加上要调用的check命令
#\cp -p -f /tmp/Nagios-0.06/Remote/nrpe.cfg /usr/local/nagios/etc/
#复制Nagios主配置文件
#\cp -p -f /tmp/Nagios-0.06/Host/nagios.cfg /usr/local/nagios/etc/
#复制remote servers的配置文件
#\cp -p -f /tmp/Nagios-0.06/Host/myservers/* /usr/local/nagios/etc/objects/myservers
#检查nrpe服务状态
systemctl status nrpe
print_ok "检查nrpe服务状态"
sleep 1
#重启nrpe服务
systemctl restart nrpe
print_ok "重启nrpe服务"
sleep 1
#检测配置文件是否 OK 的命令
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
print_ok "检测配置文件是否 OK 的命令"
sleep 2

#检查Nagios服务的状态
systemctl status nagios
print_ok "检查Nagios服务的状态"
sleep 1
#重启Nagios服务 
systemctl restart nagios
print_ok "重启Nagios服务"
sleep 1
print_ok "配置程序结束"
sleep 1

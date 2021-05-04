#!/bin/sh
#
# Author: Linfeng Zhong (Fred)
# 2021-April-06 [Initial Version] - Shell Script for Nagios Core installing
# Nagios Core - Installing Nagios Core From Source
#

#设置或显示环境变量
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#切换到 脚本 所在的目录
#1.取当前运行脚本的所在路径：　$0
#2.取当前脚本所在路径的父目录：　dirname “$0”
#3.取返回的父目录的值：　$(dirname “$0”)
#4.cd到返回的父目录：　cd “$(dirname “$0”)”
#5.输出地址：　cd “$(dirname “$0”)”,pwd
cd "$(
    cd "$(dirname "$0")" || exit
    pwd
)" || exit

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

# 版本 变量
shell_version="1.1.5.1"
shell_mode="None"
github_branch="main"
version_cmp="/tmp/version_cmp.tmp"

xray_conf_dir="/usr/local/etc/xray"
website_dir="/www/xray_web/"
xray_access_log="/var/log/xray/access.log"
xray_error_log="/var/log/xray/error.log"
cert_dir="/usr/local/etc/xray"
domain_tmp_dir="/usr/local/etc/xray"
cert_group="nobody"
#简易随机数
random_num=$((RANDOM % 12 + 4))
#从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')
WS_PATH="/$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})/"

#判断脚本类型 WS or TCP
function shell_mode_check() {
  if [ -f ${xray_conf_dir}/config.json ]; then
    if [ "$(grep -c "wsSettings" ${xray_conf_dir}/config.json)" -ge 1 ]; then
      shell_mode="ws"
    else
      shell_mode="tcp"
    fi
  else
    shell_mode="None"
  fi
}

#打印OK
function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

#打印错误
function print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}

#判定是否为root账号
function is_root() {
  if [[ 0 == "$UID" ]]; then
    print_ok "当前用户是 root 用户，开始安装流程!"
    sleep 3
  else
    print_error "当前用户不是 root 用户，请切换到 root 用户后重新执行脚本!!!"
    exit 1
  fi
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

#判定当前Linux系统的发行版本
function system_check() {

#[linfengzhong@studyaws-tk-2cpu-2gb ~]$ cat /etc/os-release 
#NAME="CentOS Linux"
#VERSION="7 (Core)"
#ID="centos"
#ID_LIKE="rhel fedora"
#VERSION_ID="7"
#PRETTY_NAME="CentOS Linux 7 (Core)"
#ANSI_COLOR="0;31"
#CPE_NAME="cpe:/o:centos:centos:7"
#HOME_URL="https://www.centos.org/"
#BUG_REPORT_URL="https://bugs.centos.org/"

#CENTOS_MANTISBT_PROJECT="CentOS-7"
#CENTOS_MANTISBT_PROJECT_VERSION="7"
#REDHAT_SUPPORT_PRODUCT="centos"
#REDHAT_SUPPORT_PRODUCT_VERSION="7"

#导入操作系统信息
  source '/etc/os-release'

  if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
    print_ok "当前系统为 Centos ${VERSION_ID} ${VERSION}"
    INS="yum install -y"
 #   wget -N -P /etc/yum.repos.d/ https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/basic/nginx.repo
  elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 9 ]]; then
    print_ok "当前系统为 Debian ${VERSION_ID} ${VERSION}"
    INS="apt install -y"
    # 清除可能的遗留问题
    rm -f /etc/apt/sources.list.d/nginx.list
    $INS lsb-release gnupg2

    echo "deb http://nginx.org/packages/debian $(lsb_release -cs) nginx" >/etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

    apt update
  elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 18 ]]; then
    print_ok "当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME}"
    INS="apt install -y"
    # 清除可能的遗留问题
    rm -f /etc/apt/sources.list.d/nginx.list
    $INS lsb-release gnupg2

    echo "deb http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" >/etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
    apt update
  else
    print_error "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内"
    exit 1
  fi

  if [[ $(grep "nogroup" /etc/group) ]]; then
    cert_group="nogroup"
  fi

  $INS dbus

  # 关闭各类防火墙
  systemctl stop firewalld
  systemctl disable firewalld
      echo -e "${OK} ${GreenBG} firewalld 已关闭 ${Font}"
  systemctl stop nftables
  systemctl disable nftables
      echo -e "${OK} ${GreenBG} nftables 已关闭 ${Font}"
  systemctl stop ufw
  systemctl disable ufw
      echo -e "${OK} ${GreenBG} ufw 已关闭 ${Font}"
}

function update_sh() {
  ol_version=$(curl -L -s https://raw.githubusercontent.com/linfengzhong/Nagios/${github_branch}/install.sh | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
  if [[ "$shell_version" != "$(echo -e "$shell_version\n$ol_version" | sort -rV | head -1)" ]]; then
    print_ok "存在新版本，是否更新 [Y/N]?"
    read -r update_confirm
    case $update_confirm in
    [yY][eE][sS] | [yY])
      wget -N --no-check-certificate hhttps://raw.githubusercontent.com/linfengzhong/Nagios/${github_branch}/install.sh
      print_ok "更新完成"
      print_ok "您可以通过 bash $0 执行本程序"
      exit 0
      ;;
    *) ;;

    esac
  else
    print_ok "当前版本为最新版本"
    print_ok "您可以通过 bash $0 执行本程序"
  fi
}

#安装必要程序
function dependency_install() {
  ${INS} wget lsof tar
  judge "安装 wget lsof tar"

  if [[ "${ID}" == "centos" ]]; then
    ${INS} crontabs
  else
    ${INS} cron
  fi
  judge "安装 crontab"

  if [[ "${ID}" == "centos" ]]; then
    touch /var/spool/cron/root && chmod 600 /var/spool/cron/root
    systemctl start crond && systemctl enable crond
  else
    touch /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
    systemctl start cron && systemctl enable cron

  fi
  judge "crontab 自启动配置 "

  ${INS} unzip
  judge "安装 unzip"

  ${INS} curl
  judge "安装 curl"

  # upgrade systemd
  ${INS} systemd
  judge "安装/升级 systemd"

  # Nginx 后置 无需编译 不再需要
  #  if [[ "${ID}" == "centos" ]]; then
  #    yum -y groupinstall "Development tools"
  #  else
  #    ${INS} build-essential
  #  fi
  #  judge "编译工具包 安装"

  if [[ "${ID}" == "centos" ]]; then
    ${INS} pcre pcre-devel zlib-devel epel-release openssl openssl-devel
  else
    ${INS} libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev
  fi

  ${INS} jq
#如不成功，安装备用库里面的jq
  if ! command -v jq; then
    wget -P /usr/bin https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/binary/jq && chmod +x /usr/bin/jq
    judge "安装 jq"
  fi
}

function nginx_install() {
  if ! command -v nginx >/dev/null 2>&1; then
    ${INS} nginx
    judge "Nginx 安装"
  else
    print_ok "Nginx 已存在"
  fi
}

function basic_optimization() {
  # 最大文件打开数
  sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
  sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
  echo '* soft nofile 65536' >>/etc/security/limits.conf
  echo '* hard nofile 65536' >>/etc/security/limits.conf

  # 关闭 Selinux
  if [[ "${ID}" == "centos" ]]; then
    sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    setenforce 0
  fi
}

#检查域名
function domain_check() {
  read -rp "请输入你的域名信息(eg: studyaws.tk):" domain
  domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
  print_ok "正在获取 IP 地址信息，请耐心等待"
  local_ip=$(curl -4 ip.sb)
  echo -e "域名通过 DNS 解析的 IP 地址：${domain_ip}"
  echo -e "本机公网 IP 地址： ${local_ip}"
  sleep 2
  if [[ ${domain_ip} == "${local_ip}" ]]; then
    print_ok "域名通过 DNS 解析的 IP 地址与 本机 IP 地址匹配"
    sleep 2
  else
    print_error "请确保域名添加了正确的 A 记录，否则将无法正常使用 xray"
    print_error "域名通过 DNS 解析的 IP 地址与 本机 IP 地址不匹配，是否继续安装？（y/n）" && read -r install
    case $install in
    [yY][eE][sS] | [yY])
      print_ok "继续安装"
      sleep 2
      ;;
    *)
      print_error "安装终止"
      exit 2
      ;;
    esac
  fi
}

#检查端口是否占用
function port_exist_check() {
  if [[ 0 -eq $(lsof -i:"$1" | grep -i -c "listen") ]]; then
    print_ok "$1 端口未被占用"
    sleep 1
  else
    print_error "检测到 $1 端口被占用，以下为 $1 端口占用信息"
    lsof -i:"$1"
    print_error "5s 后将尝试自动 kill 占用进程"
    sleep 5
    lsof -i:"$1" | awk '{print $2}' | grep -v "PID" | xargs kill -9
    print_ok "kill 完成"
    sleep 1
  fi
}

#修改xray配置文件
function xray_tmp_config_file_check_and_use() {
  if [[ -s ${xray_conf_dir}/config_tmp.json ]]; then
    mv -f ${xray_conf_dir}/config_tmp.json ${xray_conf_dir}/config.json
  else
    print_error "xray 配置文件修改异常"
  fi
}

#更改UUID
function modify_UUID() {
  [ -z "$UUID" ] && UUID=$(cat /proc/sys/kernel/random/uuid)
  cat ${xray_conf_dir}/config.json | jq 'setpath(["inbounds",0,"settings","clients",0,"id"];"'${UUID}'")' >${xray_conf_dir}/config_tmp.json
  xray_tmp_config_file_check_and_use
  judge "Xray TCP UUID 修改"
}

function modify_UUID_ws() {
  cat ${xray_conf_dir}/config.json | jq 'setpath(["inbounds",1,"settings","clients",0,"id"];"'${UUID}'")' >${xray_conf_dir}/config_tmp.json
  xray_tmp_config_file_check_and_use
  judge "Xray ws UUID 修改"
}

function modify_fallback_ws() {
  cat ${xray_conf_dir}/config.json | jq 'setpath(["inbounds",0,"settings","fallbacks",2,"path"];"'${WS_PATH}'")' >${xray_conf_dir}/config_tmp.json
  xray_tmp_config_file_check_and_use
  judge "Xray fallback_ws 修改"
}

function modify_ws() {
  cat ${xray_conf_dir}/config.json | jq 'setpath(["inbounds",1,"streamSettings","wsSettings","path"];"'${WS_PATH}'")' >${xray_conf_dir}/config_tmp.json
  xray_tmp_config_file_check_and_use
  judge "Xray ws 修改"
}

#更改端口
function modify_port() {
  read -rp "请输入端口号(默认：443)：" PORT
  [ -z "$PORT" ] && PORT="443"
  if [[ $PORT -le 0 ]] || [[ $PORT -gt 65535 ]]; then
    print_error "请输入 0-65535 之间的值"
    exit 1
  fi
  port_exist_check $PORT
  cat ${xray_conf_dir}/config.json | jq 'setpath(["inbounds",0,"port"];'${PORT}')' >${xray_conf_dir}/config_tmp.json
  xray_tmp_config_file_check_and_use
  judge "Xray 端口 修改"
}

#配置TLS版本
function tls_type() {
  echo "请选择支持的 TLS 版本（默认：TLS1.3 only）:"
  echo "1: TLS1.1, TLS1.2 and TLS1.3（兼容模式）"
  echo "2: TLS1.2 and TLS1.3 (兼容模式)"
  echo "3: TLS1.3 only"
  read -rp "请输入：" tls_version
  [[ -z ${tls_version} ]] && tls_version=3
  if [[ $tls_version == 3 ]]; then
    modify_tls_version "1.3"
  elif [[ $tls_version == 2 ]]; then
    modify_tls_version "1.2"
  else
    modify_tls_version "1.1"
  fi
}

#配置xray
function configure_xray() {
  #配置文件
  cd /usr/local/etc/xray && rm -f config.json && wget -O config.json https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/config/xray_xtls-rprx-direct.json
  #改变UUID
  modify_UUID
  #改变端口
  modify_port
  #tls种类
  tls_type
}

#配置xray websocket
function configure_xray_ws() {
  cd /usr/local/etc/xray && rm -f config.json && wget -O config.json https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/config/xray_tls_ws_mix-rprx-direct.json
  modify_UUID
  modify_UUID_ws
  modify_port
  modify_fallback_ws
  modify_ws
  tls_type
}

#安装xray
function xray_install() {
  print_ok "安装 Xray"
  curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash -s -- install
  judge "Xray 安装"

  # 用于生成 Xray 的导入链接
  echo $domain >$domain_tmp_dir/domain
  judge "域名记录"
}

#安装nginx
function nginx_install() {
  if ! command -v nginx >/dev/null 2>&1; then
    ${INS} nginx
    judge "Nginx 安装"
  else
    print_ok "Nginx 已存在"
  fi
}

#配置nginx
function configure_nginx() {
  nginx_conf="/etc/nginx/conf.d/${domain}.conf"
  cd /etc/nginx/conf.d/ && rm -f ${domain}.conf && wget -O ${domain}.conf https://raw.githubusercontent.com/wulabing/Xray_onekey/${github_branch}/config/web.conf
  sed -i "/server_name/c \\\tserver_name ${domain};" ${nginx_conf}
  judge "Nginx config modify"

  systemctl restart nginx
}

#配置伪装网站
function configure_web() {
  rm -rf /www/xray_web
  mkdir -p /www/xray_web
  wget -O web.tar.gz https://raw.githubusercontent.com/wulabing/Xray_onekey/main/basic/web.tar.gz
  tar xzf web.tar.gz -C /www/xray_web
  judge "站点伪装"
  rm -f web.tar.gz
}

#SSL证书安装
function ssl_judge_and_install() {

  mkdir -p /ssl
  if [[ -f "/ssl/xray.key" || -f "/ssl/xray.crt" ]]; then
    echo "/ssl 目录下证书文件已存在"
    print_ok "是否删除 [Y/N]?"
    read -r ssl_delete
    case $ssl_delete in
    [yY][eE][sS] | [yY])
      rm -rf /ssl/*
      print_ok "已删除"
      ;;
    *) ;;

    esac
  fi

  if [[ -f "/ssl/xray.key" || -f "/ssl/xray.crt" ]]; then
    echo "证书文件已存在"
  elif [[ -f "$HOME/.acme.sh/${domain}_ecc/${domain}.key" && -f "$HOME/.acme.sh/${domain}_ecc/${domain}.cer" ]]; then
    echo "证书文件已存在"
    "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /ssl/xray.crt --keypath /ssl/xray.key --ecc
    judge "证书应用"
  else
    mkdir /ssl
    cp -a $cert_dir/self_signed_cert.pem /ssl/xray.crt
    cp -a $cert_dir/self_signed_key.pem /ssl/xray.key
    ssl_install
    acme
  fi

  # Xray 默认以 nobody 用户运行，证书权限适配
  chown -R nobody.$cert_group /ssl/*
}

#生成证书
function generate_certificate() {
  signedcert=$(xray tls cert -domain="$local_ip" -name="$local_ip" -org="$local_ip" -expire=87600h)
  echo $signedcert | jq '.certificate[]' | sed 's/\"//g' | tee $cert_dir/self_signed_cert.pem
  echo $signedcert | jq '.key[]' | sed 's/\"//g' > $cert_dir/self_signed_key.pem
  openssl x509 -in $cert_dir/self_signed_cert.pem -noout || print_error "生成自签名证书失败"
  print_ok "生成自签名证书成功"
  chown nobody.$cert_group $cert_dir/self_signed_cert.pem
  chown nobody.$cert_group $cert_dir/self_signed_key.pem
}

#重启服务
function restart_all() {
  systemctl restart nginx
  judge "Nginx 启动"
  systemctl restart xray
  judge "Xray 启动"
}

#
function vless_xtls-rprx-direct_information() {
  UUID=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].id | tr -d '"')
  PORT=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].port)
  FLOW=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].flow | tr -d '"')
  DOMAIN=$(cat ${domain_tmp_dir}/domain)

  echo -e "${Red} Xray 配置信息 ${Font}"
  echo -e "${Red} 地址（address）:${Font}  $DOMAIN"
  echo -e "${Red} 端口（port）：${Font}  $PORT"
  echo -e "${Red} 用户 ID（UUID）：${Font} $UUID"
  echo -e "${Red} 流控（flow）：${Font} $FLOW"
  echo -e "${Red} 加密方式（security）：${Font} none "
  echo -e "${Red} 传输协议（network）：${Font} tcp "
  echo -e "${Red} 伪装类型（type）：${Font} none "
  echo -e "${Red} 底层传输安全：${Font} xtls 或 tls"
}

#
function vless_xtls-rprx-direct_link() {
  UUID=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].id | tr -d '"')
  PORT=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].port)
  FLOW=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].flow | tr -d '"')
  DOMAIN=$(cat ${domain_tmp_dir}/domain)

  print_ok "URL 链接（VLESS + TCP +  TLS）"
  print_ok "vless://$UUID@$DOMAIN:$PORT?security=tls&flow=$FLOW#TLS_wulabing-$DOMAIN"

  print_ok "URL 链接（VLESS + TCP +  XTLS）"
  print_ok "vless://$UUID@$DOMAIN:$PORT?security=xtls&flow=$FLOW#XTLS_wulabing-$DOMAIN"
  print_ok "-------------------------------------------------"
  print_ok "URL 二维码（VLESS + TCP + TLS）（请在浏览器中访问）"
  print_ok "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?security=tls%26flow=$FLOW%23TLS_wulabing-$DOMAIN"

  print_ok "URL 二维码（VLESS + TCP + XTLS）（请在浏览器中访问）"
  print_ok "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?security=xtls%26flow=$FLOW%23XTLS_wulabing-$DOMAIN"
}

#
function ws_information() {
  UUID=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].id | tr -d '"')
  PORT=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].port)
  FLOW=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].flow | tr -d '"')
  WS_PATH=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.fallbacks[2].path | tr -d '"')
  DOMAIN=$(cat ${domain_tmp_dir}/domain)

  echo -e "${Red} Xray 配置信息 ${Font}"
  echo -e "${Red} 地址（address）:${Font}  $DOMAIN"
  echo -e "${Red} 端口（port）：${Font}  $PORT"
  echo -e "${Red} 用户 ID（UUID）：${Font} $UUID"
  echo -e "${Red} 加密方式（security）：${Font} none "
  echo -e "${Red} 传输协议（network）：${Font} ws "
  echo -e "${Red} 伪装类型（type）：${Font} none "
  echo -e "${Red} 路径（path）：${Font} $WS_PATH "
  echo -e "${Red} 底层传输安全：${Font} tls "
}

function ws_link() {
  UUID=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].id | tr -d '"')
  PORT=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].port)
  FLOW=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.clients[0].flow | tr -d '"')
  WS_PATH=$(cat ${xray_conf_dir}/config.json | jq .inbounds[0].settings.fallbacks[2].path | tr -d '"')
  WS_PATH_WITHOUT_SLASH=$(echo $WS_PATH | tr -d '/')
  DOMAIN=$(cat ${domain_tmp_dir}/domain)

  print_ok "URL 链接（VLESS + TCP + TLS）"
  print_ok "vless://$UUID@$DOMAIN:$PORT?security=tls#TLS_wulabing-$DOMAIN"

  print_ok "URL 链接（VLESS + TCP + XTLS）"
  print_ok "vless://$UUID@$DOMAIN:$PORT?security=xtls&flow=$FLOW#XTLS_wulabing-$DOMAIN"

  print_ok "URL 链接（VLESS + WebSocket + TLS）"
  print_ok "vless://$UUID@$DOMAIN:$PORT?type=ws&security=tls&path=%2f${WS_PATH_WITHOUT_SLASH}%2f#WS_TLS_wulabing-$DOMAIN"
  print_ok "-------------------------------------------------"
  print_ok "URL 二维码（VLESS + TCP + TLS）（请在浏览器中访问）"
  print_ok "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?security=tls%23TLS_wulabing-$DOMAIN"

  print_ok "URL 二维码（VLESS + TCP + XTLS）（请在浏览器中访问）"
  print_ok "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?security=xtls%26flow=$FLOW%23XTLS_wulabing-$DOMAIN"

  print_ok "URL 二维码（VLESS + WebSocket + TLS）（请在浏览器中访问）"
  print_ok "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?type=ws%26security=tls%26path=%2f${WS_PATH_WITHOUT_SLASH}%2f%23WS_TLS_wulabing-$DOMAIN"
}

#基本信息展示
function basic_information() {
  print_ok "VLESS+TCP+XTLS+Nginx 安装成功"
  vless_xtls-rprx-direct_information
  vless_xtls-rprx-direct_link
}

#基本信息展示WebSocket
function basic_ws_information() {
  print_ok "VLESS+TCP+TLS+Nginx with WebSocket 混合模式 安装成功"
  ws_information
  print_ok "————————————————————————"
  vless_xtls-rprx-direct_information
  ws_link
}

#安装xray
function install_xray() {
  is_root
  system_check
  dependency_install
  basic_optimization
  domain_check
  port_exist_check 80
  xray_install
  configure_xray
  nginx_install
  configure_nginx
  configure_web
  generate_certificate
  ssl_judge_and_install
  restart_all
  basic_information
}

#安装xray_ws
function install_xray_ws() {
  is_root
  system_check
  dependency_install
  basic_optimization
  domain_check
  port_exist_check 80
  xray_install
  configure_xray_ws
  nginx_install
  configure_nginx
  configure_web
  generate_certificate
  ssl_judge_and_install
  restart_all
  basic_ws_information
}

menu() {
  #检查更新脚本
  update_sh #从GitHub更新脚本
  shell_mode_check #检查脚本模式
  
  echo -e "\t Nagios, V2ray, Xray 安装管理脚本 ${Red}[${shell_version}]${Font}"
  echo -e "\t---authored by linfeng zhong---"
  echo -e "\thttps://github.com/linfengzhong\n"

  echo -e "当前已安装版本：${shell_mode}"
  
  echo -e "——————————— 升级Linux系统 ————————————"

  echo -e "—————————————— 安装监控 ——————————————"

  echo -e "—————————————— 安装向导 ——————————————"
  echo -e "${Green}0.${Font}  升级 脚本"
  echo -e "${Green}1.${Font}  安装 Xray (VLESS + TCP + XTLS / TLS + Nginx)"
  echo -e "${Green}2.${Font}  安装 Xray (VLESS + TCP + XTLS / TLS + Nginx 及 VLESS + TCP + TLS + Nginx + WebSocket 回落并存模式)"
  echo -e "—————————————— 配置变更 ——————————————"
  echo -e "${Green}11.${Font} 变更 UUID"
  echo -e "${Green}12.${Font} 变更 TLS 最低适配版本"
  echo -e "${Green}13.${Font} 变更 连接端口"
  echo -e "${Green}14.${Font} 变更 WebSocket PATH"
  echo -e "—————————————— 查看信息 ——————————————"
  echo -e "${Green}21.${Font} 查看 实时访问日志"
  echo -e "${Green}22.${Font} 查看 实时错误日志"
  echo -e "${Green}23.${Font} 查看 Xray 配置链接"
  #    echo -e "${Green}23.${Font}  查看 V2Ray 配置信息"
  echo -e "—————————————— 其他选项 ——————————————"
  echo -e "${Green}31.${Font} 安装 4 合 1 BBR、锐速安装脚本"
  echo -e "${Yellow}32.${Font} 安装 MTproxy(不推荐使用,请相关用户关闭或卸载)"
  echo -e "${Green}33.${Font} 卸载 Xray"
  echo -e "${Green}34.${Font} 更新 Xray-core"
  echo -e "${Green}35.${Font} 安装 Xray-core 测试版(Pre)"
  echo -e "${Green}40.${Font} 退出"
  read -rp "请输入数字：" menu_num
  case $menu_num in
  0)
    update_sh
    ;;
  1)
    install_xray
    ;;
  2)
    install_xray_ws
    ;;
  11)
    read -rp "请输入UUID:" UUID
    if [[ ${shell_mode} == "tcp" ]]; then
      modify_UUID
    elif [[ ${shell_mode} == "ws" ]]; then
      modify_UUID
      modify_UUID_ws
    fi
    restart_all
    ;;
  12)
    tls_type
    restart_all
    ;;
  13)
    modify_port
    restart_all
    ;;
  14)
    if [[ ${shell_mode} == "ws" ]]; then
      read -rp "请输入路径(示例：/wulabing/ 要求两侧都包含/):" WS_PATH
      modify_fallback_ws
      modify_ws
      restart_all
    else
      print_error "当前模式不是Websocket模式"
    fi
    ;;
  21)
    tail -f $xray_access_log
    ;;
  22)
    tail -f $xray_error_log
    ;;
  23)
    if [[ -f $xray_conf_dir/config.json ]]; then
      if [[ ${shell_mode} == "tcp" ]]; then
        basic_information
      elif [[ ${shell_mode} == "ws" ]]; then
        basic_ws_information
      fi
    else
      print_error "xray 配置文件不存在"
    fi
    ;;
  31)
    bbr_boost_sh
    ;;
  32)
    mtproxy_sh
    ;;
  33)
    xray_uninstall
    ;;
  34)
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install
    restart_all
    ;;
  35)
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --beta
    restart_all
    ;;
  40)
    exit 0
    ;;
  *)
    print_error "请输入正确的数字"
    ;;
  esac
}

menu "$@"

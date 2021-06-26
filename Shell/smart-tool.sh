#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# Author: Linfeng Zhong (Fred)
# 2021-May-26 [Initial Version] - Shell Script for setup new server
# 2021-June-25 [Add new functions] - Stop/Start docker-compose
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
#notification information 通知信息
Info="${Green}[Message信息]${Font}"
OK="${Green}[OK正常]${Font}"
Error="${Red}[ERROR错误]${Font}"
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
judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 <--- 完成"
  else
    print_error "$1 <--- 失败"
    exit 1
  fi
}
#-----------------------------------------------------------------------------#
#定义变量
WORKDIR="/root/git/toolbox/Docker/docker-compose/k8s-master.ml/"
GITHUB_REPO="/root/git/toolbox/"
EMAIL="fred.zhong@outlook.com"
WEBSITE="k8s-master.ml"
#-----------------------------------------------------------------------------#
#更新脚本
function refresh_smart_tool () {
  print_info "更新smart tool脚本 "
  sudo rm -f /root/*.sh
  sudo cp -f /root/git/toolbox/Shell/smart-tool.sh /root/smart-tool.sh
  sudo chmod +x /root/*.sh
  judge "更新smart tool脚本 "
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
# 删除文件夹
function delete_docker_compose_folder () {
  print_info "删除文件夹 "
  cd ~
  sudo rm -rf k8s-master.ml/
  judge "删除文件夹 "
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
  judge "初始化 Git "
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
# 启动docker-compose
function start_docker_compose () {
  print_info "启动 Docker Compose "
  cd $WORKDIR
  sudo chmod 777 -R grafana
  sudo chmod 777 -R jenkins
  sudo docker-compose build
  sudo docker-compose up -d
  judge "启动 Docker Compose "
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
  print_info "服务器外部 IP：" && curl https://ipinfo.io/ip
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
# Install webmin
# https://webmin.com
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
# Install Git
# https://git-scm.com
#-----------------------------------------------------------------------------#
function install_git () {
  print_info "Install Git "
  sudo yum -y install git
  judge "Install Git "
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
# 展示命令选项
function usage () {
    echo "
Usage: smart-tool.sh 
              refresh
              show-ip
              down | up
              all
              delete
              git-pull | git-push ｜ git-init
              status
              turn-off-selinux
              install-prerequisite
              install-acme | generate-ca
              install-webmin
              install-git
              install-docker
              install-all"
}

RC=0

case "x$1" in 
  "xrefresh")
    github_pull
    refresh_smart_tool
    ;;
  "xshow-ip")
    show_ip
    ;;
  "xdown")
    shutdown_docker_compose
    ;;
  "xup")
    start_docker_compose
    ;;
  "xall")
    shutdown_docker_compose
    github_pull
    github_push
    start_docker_compose
    refresh_smart_tool
    ;;
  "xdelete")
    delete_docker_compose_folder
    ;;
  "xgit-push")
    github_push 
    ;;
  "xgit-pull")
    github_pull
    ;;
  "xgit-init")
    git-init
    ;;
  "xstatus")
    show_docker_images
    show_docker_container
    ;;
  "xturn-off-selinux")
    turn_off_selinux
    ;;
  "xinstall-prerequisite")
    install_prerequisite
    ;;
  "xinstall-acme")
    install_acme
    ;;
  "xgenerate-ca")
    generate_ca
    ;;
  "xinstall-webmin")
    install_webmin
    ;;
  "xinstall-git")
    install_git
    ;;
  "xinstall-docker")
    install_docker
    ;;
  "xinstall-all")
    turn_off_selinux
    install_prerequisite
    install_acme
    generate_ca
    install_webmin
    install_git
    install_docker
    ;;
  *)
    usage
esac

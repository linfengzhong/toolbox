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
sudo rm -rf all-in-one/
sudo rm -rf k8s-master.ml/
judge "删除文件夹 "
}
#-----------------------------------------------------------------------------#
# 同步下载Git文件夹
function github_pull () {
print_info "更新同步 下载GitHub文件 -> Local Github Repo "
cd $GITHUB_REPO
sudo git pull
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
sudo docker-compose build
sudo docker-compose up -d

sudo rm -f /root/*.sh
sudo cp -f /root/git/toolbox/Shell/smart-tool.sh /root/smart-tool.sh
sudo chmod +x /root/*.sh
judge "启动 Docker Compose "
}
#-----------------------------------------------------------------------------#
# 展示命令选项
function usage () {
    echo "
Usage: smart-tool.sh down|up
              all
              delete
              git-push|git-pull
              docker-status"
}

RC=0

case "x$1" in 
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
    ;;
  "xdelete")
    delete_docker_compose_folder
    ;;
  "xgithub-push")
    github_push ;;
  "xgit-pull")
    git_pull
    ;;
  "xstatus")
    show_docker_images
    show_docker_container
    ;;
  *)
    usage
esac

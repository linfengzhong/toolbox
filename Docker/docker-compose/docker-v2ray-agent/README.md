#!/usr/bin/env bash
# 八合一共存脚本+伪装站点
# 1. VLESS+TCP+TLS
# 2. VLESS+TCP+xtls-rprx-direct【推荐】
# 3. VLESS+gRPC+TLS【支持CDN、IPv6】
# 4. VLESS+WS+TLS【支持CDN、IPv6】
# 5. VMess+TCP+TLS
# 6. VMess+WS+TLS【支持CDN、IPv6】
# 7. Trojan【推荐】
# 8. Trojan-Go+WS【支持CDN、不支持IPv6】
# ---------------------------------
# 脚本目录
# ---------------------------------
# Xray-core
# 主目录
# /etc/v2ray-agent/xray
# 配置文件目录
# /etc/v2ray-agent/xray/conf
# ---------------------------------
# v2ray-core
# 主目录
# /etc/v2ray-agent/v2ray
# 配置文件目录
# /etc/v2ray-agent/v2ray/conf
# ---------------------------------
# Trojan
# 目录
# /etc/v2ray-agent/trojan
# 配置文件
# /etc/v2ray-agent/trojan/config_full.json
# ---------------------------------
# TLS证书
# 目录
# /etc/v2ray-agent/tls
# ---------------------------------
# Nginx
# Nginx配置文件
# /etc/nginx/conf.d/alone.conf
# Nginx伪装站点目录
# /usr/share/nginx/html
# 安装最新版本脚本：
# wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/linfengzhong/toolbox/main/install_8in1_xray.sh" && chmod 700 /root/install_8in1_xray.sh && /root/install_8in1_xray.sh
#
# -------------------------------------------------------------
# 检测区
# -------------------------------------------------------------
# 检查系统
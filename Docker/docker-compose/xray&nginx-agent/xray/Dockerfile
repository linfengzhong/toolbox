# Dockerfile for xray based alpine
# Copyright (C) 2019 - 2021 linfengzhong <linfengzhong@outlook.com>
# Reference URL:
# https://github.com/XTLS/Xray-core
# https://github.com/v2fly/v2ray-core
# https://github.com/v2fly/geoip
# https://github.com/v2fly/domain-list-community

## bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

FROM alpine:latest
LABEL maintainer="linfengzhong <linfengzhong@outlook.com>"

WORKDIR /
COPY xray-v1.4.2 /usr/bin/xray
COPY conf.d /etc/xray/conf.d

RUN set -ex \
	&& apk add --no-cache tzdata ca-certificates \
	&& mkdir -p /var/log/xray /usr/local/share/xray \
	&& chmod +x /usr/bin/xray \
	&& wget -O /usr/local/share/xray/geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat \
	&& wget -O /usr/local/share/xray/geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat

VOLUME /etc/xray
ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/xray", "-confdir", "/etc/xray/conf.d" ]

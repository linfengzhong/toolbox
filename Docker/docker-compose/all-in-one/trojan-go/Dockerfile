# Dockerfile for trojan-go based alpine
# Copyright (C) 2019 - 2021 Fred <fred.zhong@outlook.com>
# Reference URL:
# https://github.com/p4gefau1t/trojan-go
# https://github.com/v2ray/v2ray-core
# https://github.com/v2ray/geoip
# https://github.com/v2ray/domain-list-community

FROM alpine:latest
LABEL maintainer="Fred <fred.zhong@outlook.com>"

COPY trojan-go-v0.10.2 /usr/bin/trojan-go
COPY config.json /etc/trojan-go/config.json
COPY shanghai3721.ml.crt /etc/trojan-go/tls/shanghai3721.ml.crt
COPY shanghai3721.ml.key /etc/trojan-go/tls/shanghai3721.ml.key
COPY geoip.dat /etc/trojan-go/geoip.dat
COPY geosite.dat /etc/trojan-go/geosite.dat

RUN set -ex \
	&& apk add --no-cache tzdata ca-certificates \
	&& chmod +x /usr/bin/trojan-go \
	&& wget -O /usr/bin/geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat \
	&& wget -O /usr/bin/geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat

VOLUME /etc/trojan-go
ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/trojan-go", "-config", "/etc/trojan-go/config.json" ]

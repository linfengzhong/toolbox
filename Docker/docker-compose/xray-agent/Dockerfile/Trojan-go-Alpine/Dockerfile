# Dockerfile for trojan-go based alpine
# Copyright (C) 2019 - 2021 Fred <fred.zhong@outlook.com>
# Reference URL:
# https://github.com/p4gefau1t/trojan-go
# https://github.com/v2ray/v2ray-core
# https://github.com/v2ray/geoip
# https://github.com/v2ray/domain-list-community

FROM alpine:latest
LABEL maintainer="Fred <fred.zhong@outlook.com>"

COPY trojan-go-v0.10.0 /usr/bin/trojan-go
COPY config.yml /etc/trojan-go/config.yml
COPY geoip.dat /etc/trojan-go/geoip.dat
COPY geosite.dat /etc/trojan-go/geosite.dat
COPY shanghai3721.ml.pem /etc/trojan-go/tls/shanghai3721.ml.pem
COPY shanghai3721.ml.key.pem /etc/trojan-go/tls/shanghai3721.ml.key.pem

RUN set -ex \
	&& apk add --no-cache tzdata ca-certificates \
	&& chmod +x /usr/bin/trojan-go

VOLUME /etc/trojan-go
ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/trojan-go", "-config", "/etc/trojan-go/config.yml" ]

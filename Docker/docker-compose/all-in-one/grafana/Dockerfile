# Dockerfile for trojan-go based alpine
# Copyright (C) 2019 - 2021 Fred <fred.zhong@outlook.com>
# Reference URL:
# https://github.com/p4gefau1t/trojan-go

FROM grafana/grafana:latest
LABEL maintainer="Fred <fred.zhong@outlook.com>"

COPY grafana.ini /etc/grafana/grafana.ini
COPY shanghai3721.ml.crt /etc/grafana/shanghai3721.ml.crt
COPY shanghai3721.ml.key /etc/grafana/shanghai3721.ml.key

RUN set -ex \
	&& apk add --no-cache tzdata ca-certificates \
	&& chmod 644 /etc/grafana/shanghai3721.ml.crt \
	&& chmod 644 /etc/grafana/shanghai3721.ml.key

USER grafana
WORKDIR /
ENTRYPOINT [ "/run.sh" ]

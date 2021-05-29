# Dockerfile for alertmanager based prom/alertmanage
# Copyright (C) 2019 - 2021 Fred <fred.zhong@outlook.com>
# Reference URL:
# https://github.com/p4gefau1t/trojan-go

FROM prom/alertmanager:latest
LABEL maintainer="Fred <fred.zhong@outlook.com>"

COPY alertmanager.yml /etc/alertmanager/alertmanager.yml

RUN chmod 666 /etc/alertmanager/alertmanager.yml
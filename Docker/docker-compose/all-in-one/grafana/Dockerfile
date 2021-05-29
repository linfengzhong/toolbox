# Dockerfile for trojan-go based alpine
# Copyright (C) 2019 - 2021 Fred <fred.zhong@outlook.com>
# Reference URL:
# https://github.com/p4gefau1t/trojan-go

FROM grafana/grafana:latest
LABEL maintainer="Fred <fred.zhong@outlook.com>"

COPY ./data/ /var/lib/grafana/

RUN chmod -R 777 /var/lib/grafana/

USER grafana
WORKDIR /
ENTRYPOINT [ "/run.sh" ]
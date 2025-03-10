FROM ghcr.io/planetscale/ghcommit:v0.1.24@sha256:0c61e7dbf31f9c499de923da8fc8ceb0990bb33c69e306809b3c37fd4282c347 AS ghcommit

FROM pscale.dev/wolfi-prod/base:latest AS base

COPY --from=ghcommit /ghcommit /usr/bin/ghcommit

RUN apk add --no-cache \
        bash \
        git

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

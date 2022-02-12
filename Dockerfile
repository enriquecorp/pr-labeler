FROM alpine:3.10

RUN apk add --no-cache bash curl jq bc

ADD entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
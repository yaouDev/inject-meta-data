FROM alpine:3.18

RUN apk add --no-cache jq

WORKDIR /github/workspace

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT
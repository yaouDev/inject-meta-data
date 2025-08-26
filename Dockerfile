FROM alpine/git:2.44.0

RUN apk add --no-cache jq bash

WORKDIR /app

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
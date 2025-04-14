FROM golang:1.24.0-alpine AS builder

RUN apk add --update --no-cache git
RUN go install github.com/googlecloudplatform/gcsfuse/v2@v2.11.1
RUN go install github.com/charmbracelet/soft-serve/cmd/soft@v0.8.5

FROM alpine:latest

COPY --from=builder /go/bin/gcsfuse /usr/local/bin/gcsfuse
COPY --from=builder /go/bin/soft /usr/local/bin/soft
RUN apk add --update --no-cache ca-certificates fuse
RUN apk add --update --no-cache git bash openssh 

RUN apk add --update --no-cache parallel

WORKDIR /soft-serve
ENV SOFT_SERVE_DATA_PATH="/soft-serve"
ENV SOFT_SERVE_INITIAL_ADMIN_KEYS=""
ENV GCSFUSE_BUCKET=""
EXPOSE 22

COPY config.yaml /root
COPY --chmod=0755 entrypoint.sh /root

ENTRYPOINT ["/root/entrypoint.sh"]

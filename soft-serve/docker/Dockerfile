FROM alpine:latest AS base
RUN apk add --update curl bash python3
RUN set -o pipefail \
  && curl -sSL https://sdk.cloud.google.com | bash \
  && /root/google-cloud-sdk/bin/gcloud components remove bq gsutil --quiet
ENV PATH="$PATH:/root/google-cloud-sdk/bin"

FROM golang:1.27.2-alpine AS build
WORKDIR /build
COPY soft-serve/go.mod soft-serve/go.sum .
RUN go mod download
COPY soft-serve/ .
RUN go install ./cmd/soft

FROM base AS test
COPY --from=build /go/bin/soft /usr/local/bin/soft
RUN apk add --update --no-cache git openssh

WORKDIR /soft-serve
ENV SOFT_SERVE_DATA_PATH="/soft-serve"
ENV SOFT_SERVE_INITIAL_ADMIN_KEYS=""
ENV SOFT_SERVE_GCS_BACKUP_BUCKET=""
EXPOSE 22

COPY test-config.yaml /root/config.yaml
COPY --chmod=0755 entrypoint.sh /root

ENTRYPOINT ["/root/entrypoint.sh"]

FROM test AS final
COPY config.yaml /root/config.yaml

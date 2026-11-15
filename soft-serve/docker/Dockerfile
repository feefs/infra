FROM alpine:3.24.4 AS base
RUN apk add --no-cache curl python3
ARG GCLOUD_VERSION=593.0.0
ARG GCLOUD_SHA256=42c32b7553c712f71fcf6f124546c0519437f53755f47f9bd0c957998cd6b826
RUN curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz" -o /tmp/google-cloud-cli.tar.gz \
  && echo "${GCLOUD_SHA256}  /tmp/google-cloud-cli.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/google-cloud-cli.tar.gz -C /opt \
  && rm -f /tmp/google-cloud-cli.tar.gz \
  && /opt/google-cloud-sdk/bin/gcloud components remove bq gsutil --quiet \
  && chmod -R a+rX /opt/google-cloud-sdk
ENV PATH="/opt/google-cloud-sdk/bin:$PATH"
ENV CLOUDSDK_CORE_DISABLE_PROMPTS=1
ENV CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=true

FROM golang:1.27.4-alpine3.24 AS build
WORKDIR /build
COPY soft-serve/go.mod soft-serve/go.sum .
RUN go mod download
COPY soft-serve/ .
RUN go install ./cmd/soft

FROM base AS test
COPY --from=build /go/bin/soft /usr/local/bin/soft
RUN apk add --no-cache git openssh-client-default

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

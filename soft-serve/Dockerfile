FROM ghcr.io/charmbracelet/soft-serve:v0.8.2

RUN apk add --update curl python3
RUN set -o pipefail && curl -sSL https://sdk.cloud.google.com | bash
ENV PATH="$PATH:/root/google-cloud-sdk/bin"

COPY config.yaml /soft-serve/config.yaml

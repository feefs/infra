#!/bin/sh
set -eux
cp /etc/soft-serve/config.yaml "${SOFT_SERVE_DATA_PATH}/config.yaml"

NO_COLOR=1 exec /usr/local/bin/soft serve 2>&1

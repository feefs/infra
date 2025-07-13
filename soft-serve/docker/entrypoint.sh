#!/bin/bash
set -eux
cp /root/config.yaml ${SOFT_SERVE_DATA_PATH}
mkdir -p ${SOFT_SERVE_DATA_PATH}/bundles

NO_COLOR=1 exec /usr/local/bin/soft serve 2>&1

#!/bin/bash
set -euxo pipefail
gcsfuse --app-name=soft-serve ${GCSFUSE_BUCKET} /soft-serve
mount | grep gcsfuse
cp /root/config.yaml /soft-serve
NO_COLOR=1 exec /usr/local/bin/soft serve 2>&1

#!/bin/bash
set -euxo pipefail
gcsfuse \
  --app-name=soft-serve \
  --file-mode=744 \
  ${GCSFUSE_BUCKET} /soft-serve
mount | grep gcsfuse
cp /root/config.yaml /soft-serve
NO_COLOR=1 exec /usr/local/bin/soft serve 2>&1

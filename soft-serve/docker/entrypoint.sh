#!/bin/bash
set -euxo pipefail
gcsfuse \
  --app-name=soft-serve \
  --file-mode=744 \
  --log-file=/tmp/gcsfuse-logs.log \
  ${GCSFUSE_BUCKET} /soft-serve
mount | grep gcsfuse
cp /root/config.yaml /soft-serve
parallel --no-notice --halt soon,fail=1 --line-buffer ::: \
  "tail -f /tmp/gcsfuse-logs.log" \
  "NO_COLOR=1 SOFT_SERVE_DEBUG=1 SOFT_SERVE_VERBOSE=1 /usr/local/bin/soft serve 2>&1"

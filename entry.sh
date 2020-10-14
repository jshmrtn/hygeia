#!/bin/sh

set -eux

export RELEASE_NAME="hygeia"

if { [ -z "${RELEASE_DISTRIBUTION:-}" ] || [ "$RELEASE_DISTRIBUTION" = "name" ]; } && [ -z "${RELEASE_NODE:-}" ]; then
  export RELEASE_DISTRIBUTION="name"
  if [ -n "${POD_IP:-}" ] && [ -n "${KUBERNETES_NAMESPACE:-}" ]; then
    POD_NAME="$(echo "$POD_IP" | sed 's/\./-/g')"
    RELEASE_HOST="${POD_NAME}.${KUBERNETES_NAMESPACE}.pod.cluster.local"
  else
    RELEASE_HOST="$(hostname -f)"
  fi
  export RELEASE_NODE="${RELEASE_NAME}@${RELEASE_HOST}"
fi

exec /app/bin/hygeia "$@"

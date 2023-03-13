#!/usr/bin/env bash

NAMESPACE="$1"
SECRET_NAME="$2"
DEST_DIR="$3"

#export PATH="${BIN_DIR}:${PATH}"

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"/

if [[ -n "${LICENSE}" ]] &&  [[ -n "${LICENSE_KEY}" ]]; then
  kubectl create secret generic "${SECRET_NAME}" \
    --from-literal="${LICENSE_KEY}=${LICENSE}" \
    -n "${NAMESPACE}" \
    --dry-run=client \
    --output=yaml > "${DEST_DIR}/${SECRET_NAME}.yaml"
fi
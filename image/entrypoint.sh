#!/usr/bin/env sh

## TODO
# - how do we version the shim?
# - add shasum check to ensure the shim is not corrupted and matches the expected version
# - add a label/taint/toleration when the shim is installed to indicate it accepts spin apps
# - add aforementioned label/taint/toleration to the containerd config

set -euo

run_as_host() {
  nsenter -m /proc/1/ns/mnt -- "$@"
}

log() { 
  echo "$(date -Iseconds) [$1] $(printf '%s' "${*}" | cut -f 2 -w)"
}

panic() {
  log error "${@}"
  debug
  exit 1
}

get_runtime_type() {
  toml get -r "${1}" 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin.runtime_type'
}

set_runtime_type() {
  log info "adding spin runtime '${RUNTIME_TYPE}' to ${HOST_CONTAINERD_CONFIG}"
  tmpfile=$(mktemp)
  toml set "${HOST_CONTAINERD_CONFIG}" 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin.runtime_type' "${RUNTIME_TYPE}" > "${tmpfile}"

  # ensure the runtime_type was set
  if [ "$(get_runtime_type "${tmpfile}")" = "${RUNTIME_TYPE}" ]; then
    # overwrite the containerd config with the temp file
    mv "${tmpfile}" "${HOST_CONTAINERD_CONFIG}"
    log info "committed changes to containerd config"
  else
    panic "failed to set runtime_type to ${RUNTIME_TYPE}"
  fi
}

HOST_CONTAINERD_CONFIG="${HOST_CONTAINERD_CONFIG:-/host/etc/containerd/config.toml}"
HOST_BIN="${HOST_BIN:-/host/bin}"

# provide default values if none provided
RUNTIME_TYPE="io.containerd.spin.v1"
RUNTIME_HANDLE="spin"

# check that the shim binary is included in the docker image
if [ ! -f "./containerd-shim-spin-v1" ]; then
  panic "shim binary not found"
fi

# check that the host's bin directory exists
if [ ! -d "${HOST_BIN}" ]; then
  panic "one of the host's bin directories should be mounted to ${HOST_BIN}"
fi

# check that the containerd config path exists
if [ ! -f "${HOST_CONTAINERD_CONFIG}" ]; then
  panic "containerd config '${HOST_CONTAINERD_CONFIG}' does not exist"
fi

log info "copying the shim to the node's bin directory '${HOST_BIN}'"
cp "./containerd-shim-spin-v1" "${HOST_BIN}"

# check if the shim is already in the containerd config
if [ "$(get_runtime_type "${HOST_CONTAINERD_CONFIG}")" = "${RUNTIME_TYPE}" ]; then
  log info "runtime_type is already set to ${RUNTIME_TYPE}"
else
  set_runtime_type
fi

# for debugging purposes, remove before release
if [ "${DEBUG:-false}" = true ]; then
  # sleep for 5 seconds to allow the containerd service to restart
  sleep 5
  debug
  while true; do sleep 60; done
fi

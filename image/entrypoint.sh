#!/usr/bin/env sh

set -euo

##
# variables
##
HOST_CONTAINERD_CONFIG="${HOST_CONTAINERD_CONFIG:-/host/etc/containerd/config.toml}"
HOST_BIN="${HOST_BIN:-/host/bin}"
RUNTIME_TYPE="io.containerd.spin.v1"
RUNTIME_HANDLE="spin"

##
# helper functions
##
run_as_host() {
  nsenter -m /proc/1/ns/mnt -- "$@"
}

get_runtime_type() {
  toml get -r "${1}" 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin.runtime_type'
}

set_runtime_type() {
  echo "adding spin runtime '${RUNTIME_TYPE}' to ${HOST_CONTAINERD_CONFIG}"
  tmpfile=$(mktemp)
  toml set "${HOST_CONTAINERD_CONFIG}" 'plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin.runtime_type' "${RUNTIME_TYPE}" > "${tmpfile}"

  # ensure the runtime_type was set
  if [ "$(get_runtime_type "${tmpfile}")" = "${RUNTIME_TYPE}" ]; then
    # overwrite the containerd config with the temp file
    mv "${tmpfile}" "${HOST_CONTAINERD_CONFIG}"
    echo "committed changes to containerd config"
  else
    echo "failed to set runtime_type to ${RUNTIME_TYPE}"
    exit 1
  fi
}

##
# assertions
##
if [ ! -f "./containerd-shim-spin-v1" ]; then
  echo "shim binary not found"
  exit 1
fi

if [ ! -d "${HOST_BIN}" ]; then
  echo "one of the host's bin directories should be mounted to ${HOST_BIN}"
  exit 1
fi

if [ ! -f "${HOST_CONTAINERD_CONFIG}" ]; then
  echo "containerd config '${HOST_CONTAINERD_CONFIG}' does not exist"
  exit 1
fi

echo "copying the shim to the node's bin directory '${HOST_BIN}'"
cp "./containerd-shim-spin-v1" "${HOST_BIN}"

# check if the shim is already in the containerd config
if [ "$(get_runtime_type "${HOST_CONTAINERD_CONFIG}")" = "${RUNTIME_TYPE}" ]; then
  echo "runtime_type is already set to ${RUNTIME_TYPE}"
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

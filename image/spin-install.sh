#!/usr/bin/env bash

## VARIABLES
# HOST_ROOT: the root directory of the host filesystem
# DEBUG: if set to true, will print out debug information

## TODO
# - how do we version the shim?
# - add shasum check to ensure the shim is not corrupted and matches the expected version
# - add a label/taint/toleration when the shim is installed to indicate it accepts spin apps
# - add aforementioned label/taint/toleration to the containerd config

set -euo pipefail

run_as_host() {
  nsenter -m/$HOST_ROOT/proc/1/ns/mnt -- $@
}

log() {
  echo "$(date -Ins) [$1] ${@:2}"
}

debug() {
  log debug "dumping debug information"
  log debug "target_path: ${target_path}"
  run_as_host ls -al "${host_target_path}"
  log debug "host PATH env"
  run_as_host printenv PATH
  log debug "containerd_config_path: ${containerd_config_path}"
  run_as_host ls -al $(dirname "${host_containerd_config_path}")
  cat $containerd_config_path
  log debug "check containerd"
  run_as_host which systemctl
  run_as_host systemctl status containerd
}

panic() {
  log error "${@}"
  debug
  exit 1
}

# This script copies the shim to the node and configures containerd to use them
# Options:
#   -s: source path to containerd shim (default: ./containerd-shim-spin-v1)
#   -t: target path to copy the shim (default: /bin/)
#   -c: containerd config path (default: /etc/containerd/config.toml)
while getopts s:t:c: flag
do
    case "${flag}" in
        s) source_path=${OPTARG};;
        t) target_path=${OPTARG};;
        c) containerd_config_path=${OPTARG};;
    esac
done

# check that the HOST_ROOT environment variable is set
if [ -z "${HOST_ROOT}" ]; then
  panic "HOST_ROOT environment variable is not set"
fi

# provide default values if none provided
source_path="${source_path:-./containerd-shim-spin-v1}"
host_target_path="${target_path:-/usr/local/bin}"
host_containerd_config_path="${containerd_config_path:-/etc/containerd/config.toml}"
target_path="${HOST_ROOT}${host_target_path}"
containerd_config_path="${HOST_ROOT}${host_containerd_config_path}"

# check that the source path exists
if [ ! -f "${source_path}" ]; then
  panic "Source path ${source_path} does not exist"
fi

# check that the target path exists
if [ ! -d "${target_path}" ]; then
  panic "Target path ${target_path} does not exist"
fi

# check that the containerd config path exists
if [ ! -f "${containerd_config_path}" ]; then
  panic "Containerd config path ${containerd_config_path} does not exist"
fi

log info "copy the shim to the node's bin directory"
cp ${source_path} ${target_path}

# check if the shim is already in the containerd config
if grep -q "io.containerd.spin.v1" ${containerd_config_path}; then
  log info "shim already in containerd config"
else
  log info "add the shim to the containerd config"
  cat << EOF >> ${containerd_config_path}

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin]
  runtime_type = "io.containerd.spin.v1"
EOF

  log info "restarting containerd"
  run_as_host systemctl restart containerd
fi

# if DEBUG enabled, print out debug information and sleep in a loop
if [ "${DEBUG:-false}" = true ]; then
  # sleep for 5 seconds to allow the containerd service to restart
  sleep 5
  debug
  while true; do sleep 60; done
fi

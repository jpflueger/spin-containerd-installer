#!/usr/bin/env bash

set -e

# This script downloads the containerd-wasm-shims
# Options:
#   -v: shim version (default: 0.5.1)
#   -r: shim repo (default: deislabs/containerd-wasm-shims)
while getopts v:r: flag
do
    case "${flag}" in
        v) shim_version=${OPTARG};;
        r) shim_repo=${OPTARG};;
    esac
done

# provide default values if none provided
shim_version=${shim_version:-0.5.1}
shim_repo=${shim_repo:-deislabs/containerd-wasm-shims}
shim_arch=$(uname -m)

# verify the version is valid
if [[ ! ${shim_version} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "invalid shim version: ${shim_version}"
    exit 1
fi

# verify the architecture is valid
if [[ ! ${shim_arch} =~ ^(aarch64|x86_64)$ ]]; then
    echo "invalid shim architecture: ${shim_arch}"
    exit 1
fi

# download and extract the spin shim
rel="https://github.com/${shim_repo}/releases/download/v${shim_version}/containerd-wasm-shims-v1-linux-${shim_arch}.tar.gz"
tar -xvz -f <(wget -q -O - ${rel}) containerd-shim-spin-v1

# spin-containerd-installer

This project provides an automated method to install and configure the containerd shim for Fermyon Spin in Kubernetes.

## Versions

The version of the container image and Helm chart directly correlates to the version of the containerd shim. For simplicity, here is a table depicting the version matrix between Spin and the containerd shim.

| containerd-shim-spin-v1                                                         | Spin                                                          |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| [v0.6.0](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.6.0) | [v1.1.0](https://github.com/fermyon/spin/releases/tag/v1.1.0) |
| [v0.5.1](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.5.1) | [v1.0.0](https://github.com/fermyon/spin/releases/tag/v1.0.0) |
| [v0.5.0](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.5.0) | [v0.9.0](https://github.com/fermyon/spin/releases/tag/v0.9.0) |

## Installation Requirements

At a high level, in order to add a new runtime shim to containerd we must accomplish the following:

1. Adding the `containerd-shim-spin-v1` binary to the node's path (default location: `/usr/local/bin`)
2. Appending the `containerd-shim-spin-v1` runtime to containerd's config (default location: `/etc/containerd/config.toml`)
4. Applying a `RuntimeClass` that you can specify in a pod's spec for containerd to use

Because of these constraints, installing an additional runtime for containerd requires *privileged access* to a node. Currently this repository only contains a way to install the runtime shim via Kubernetes resources but another option would be to customize a base image for your nodes with these constraints in mind. 

### Install via Helm

This project provides a Helm chart that includes a [DaemonSet](chart/templates/daemonset.yaml) which runs an [init container](image/Dockerfile) *in privileged mode* in order to copy the binary to the node and update the containerd config with the new runtime. This is the most generic way to install the containerd runtime shim in Kubernetes environments.

```shell
helm install spin-installer ./chart
```

We are currently working on getting the Helm chart into an artifact repository so it might be easier to clone this repository and install from local until then.

## Disclaimer

As mentioned above, the Helm chart's method of installation does currently require privileged access to a node. Please be sure to review the [DaemonSet](chart/templates/daemonset.yaml), install script [entrypoint.sh](image/entrypoint.sh) and accompanying [Dockerfile](image/Dockerfile).

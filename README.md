# spin-containerd-installer

> Warning! This repository is under active development and changes are being pushed frequently. Make sure to pull down changes frequently.

This repo contains a Kubernetes DaemonSet that is able to add the `containerd-shim-spin-v1` to the node's path and configure it as another runtime for containerd.

# Requirements

- Docker
- kubectl
- Kubernetes cluster

# Shim Versions

For versions of the containerd shim, you can check the releases page on the [github.com/deislabs/containerd-wasm-shims](https://github.com/deislabs/containerd-wasm-shims/releases).

The docker image for the DaemonSet Installer currently defaults to [v5.0.1](https://github.com/deislabs/containerd-wasm-shims/releases/tag/v0.5.1)

## Installing on nodes using the DaemonSet

Installing an additional runtime to containerd on a Kubernetes cluster currently requires three things:

1. Adding the `containerd-shim-spin-v1` binary to the node's path (defaults location: `/usr/local/bin`)
2. Appending the `containerd-shim-spin-v1` to containerd's config.toml (default location: `/etc/containerd/config.toml`)
3. Restarting the containerd process `systemctl restart containerd`
4. Applying a `RuntimeClass` that you can specify in a pod's spec for containerd to use

Installing an additional runtime for containerd requires access to a node. Because of this constraint, this repository contains a [DaemonSet](manifests/ds-installer.yaml) that runs a [Docker container](image/Dockerfile) *in privileged mode with the node's filesystem mounted* which is able to copy the binary to the node and update the containerd config with the new runtime. This is the most generic way to install the containerd runtime shim. If you have security concerns over this method of installation, please file an issue so we can cover your use-case as well.

### Building the DaemonSet's Docker image

The [Makefile](Makefile) contains a target that will build the docker image for you. You can use the Makefile target like this if you'd like to customize the image's registry, repo or tag:

```shell
SHIM_VERSION=5.0.1 DOCKER_IMAGE=my-registry/spin-containerd-installer make docker-build
```

The `SHIM_VERSION` variable is used as the tag for the container image.

The command to build the image is also fairly simple, simply replace `<shim-version>` and `<image-tag>` with the your chosen values:

```shell
docker buildx build --platform linux/amd64,linux/arm64/v8 --build-arg <shim-version> --tag <image-tag> ./image
```

Make sure to push the image before applying the DaemonSet:

```shell
SHIM_VERSION=5.0.1 DOCKER_IMAGE=my-registry/spin-containerd-installer make docker-push
```

There is also a Makefile target that will build and push the container image for you:

```shell
SHIM_VERSION=5.0.1 DOCKER_IMAGE=my-registry/spin-containerd-installer make docker-build-and-push
```

### Deploying the DaemonSet & RuntimeClass

The [Makefile](Makefile) contains a target that will apply the DaemonSet and RuntimeClass for you, just make sure to edit the manifest with your values for the `SHIM_VERSION` and `DOCKER_IMAGE` variables if you adjusted them when building and pushing the docker image:

```shell
make k8s-apply
```

Alternatively you can directly apply the manifests:

```
kubectl apply -f manifests/ds-installer.yaml
kubectl apply -f manifests/rc-spin.yaml
```

### Installation Script

You can evaluate the [./image/spin-install.sh] script for the docker container which is the primary entrypoint. The only requirement for now is setting the `HOST_ROOT` variable to the location of the host filesystem's mount point. At a high level, it accomplishes three things:

1. Copy the `containerd-shim-spin-v1` binary to the host at `/usr/local/bin`. This can be overridden by setting the container's command in the DaemonSet like `./spin-install.sh -t /bin`.
2. Append the runtime to containerd's config.toml located at `/etc/containerd/config.toml`
3. Restart the containerd service.

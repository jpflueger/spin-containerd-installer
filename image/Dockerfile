FROM ubuntu:18.04

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y wget

WORKDIR /work

# Download and install containerd-shim-spin
COPY ./spin-download.sh .
ARG VERSION=0.5.1
RUN ./spin-download.sh -v $VERSION

# Add the install script to be run by the k8s daemonset
COPY ./spin-install.sh .

CMD ["./spin-install.sh"]

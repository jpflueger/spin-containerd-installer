SHIM_VERSION ?= 0.6.0
IMAGE_REPO ?= docker.io/jpflueger/spin-containerd-installer
IMAGE_TAG ?= latest
PLATFORM ?= linux/arm64

.PHONY: docker-build-and-push
docker-build-and-push: docker-build docker-push

.PHONY: docker-build
docker-build:
	docker buildx build --platform $(PLATFORM) --build-arg SHIM_VERSION=$(SHIM_VERSION) --tag $(IMAGE_REPO):$(IMAGE_TAG) ./image

.PHONY: docker-push
docker-push:
	docker buildx build --push --platform $(PLATFORM) --build-arg SHIM_VERSION=$(SHIM_VERSION) --tag $(IMAGE_REPO):$(IMAGE_TAG) ./image

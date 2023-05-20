SHIM_VERSION ?= 0.6.0
DOCKER_IMAGE ?= jpflueger/spin-containerd-installer:$(SHIM_VERSION)

.PHONY: docker-build
docker-build:
	docker buildx build --platform linux/amd64,linux/arm64/v8 --build-arg $(SHIM_VERSION) --tag $(DOCKER_IMAGE) ./image

.PHONY: docker-push
docker-push:
	docker buildx build --push --platform linux/amd64,linux/arm64/v8 --build-arg $(SHIM_VERSION) --tag $(DOCKER_IMAGE) ./image

.PHONY: docker-build-and-push
docker-build-and-push: docker-build docker-push

.PHONY: k8s-apply
k8s-apply:
	kubectl apply -f ./manifests/ds-installer.yaml
	kubectl apply -f ./manifests/rc-spin.yaml

.PHONY: k8s-delete
k8s-delete:
	kubectl delete --ignore-not-found -f ./manifests/ds-installer.yaml
	kubectl delete --ignore-not-found -f ./manifests/rc-spin.yaml
	kubectl delete --ignore-not-found --wait=false -f ./manifests/debug.yaml

.PHONY: k8s-restart
k8s-restart: k8s-delete docker-build-and-push k8s-apply

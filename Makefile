SHIM_VERSION ?= 0.5.1
DOCKER_IMAGE ?= jpflueger/spin-containerd-installer:$(SHIM_VERSION)

.PHONY: build-and-push
build-and-push:
	docker buildx build --push --platform linux/amd64,linux/arm64/v8 --build-arg $(SHIM_VERSION) --tag $(DOCKER_IMAGE) ./image

.PHONY: apply
apply:
	kubectl apply -f ./manifests/ds-installer.yaml
	kubectl apply -f ./manifests/rc-spin.yaml

.PHONY: delete
delete:
	kubectl delete --ignore-not-found -f ./manifests/ds-installer.yaml
	kubectl delete --ignore-not-found -f ./manifests/rc-spin.yaml
	kubectl delete --ignore-not-found --wait=false -f ./manifests/debug.yaml

.PHONY: restart
restart: delete build-and-push apply

.PHONY: debug
debug:
	kubectl delete --ignore-not-found -f ./manifests/debug.yaml
	kubectl apply --wait=true -f ./manifests/debug.yaml
	echo "Run this command to attach to debug pod: 'kubectl exec -it debug -- /bin/bash'"

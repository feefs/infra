IMAGE_NAME = $(shell tofu output --raw soft_serve_image_name)
TEST_IMAGE_NAME := $(IMAGE_NAME)-test
TEST_CONTAINER_NAME := soft-serve-test

.PHONY: build_soft_serve push_soft_serve test_soft_serve clean prune
.IGNORE: clean prune

build_soft_serve:
	docker build soft-serve/docker --tag $(IMAGE_NAME)

push_soft_serve:
	docker push $(IMAGE_NAME)

test_soft_serve:
	docker build soft-serve/docker --tag $(TEST_IMAGE_NAME) --target test
	mkdir -p $(CURDIR)/data
	if [ -z "$(SOFT_SERVE_INITIAL_ADMIN_KEYS)" ]; then \
		echo "export SOFT_SERVE_INITIAL_ADMIN_KEYS="..." environment variable is required."; \
		exit 1; \
	fi
	-docker stop $(TEST_CONTAINER_NAME)
	docker run --rm --detach \
		--name $(TEST_CONTAINER_NAME) \
		--user "$$(id -u):$$(id -g)" \
		--env HOME=/tmp \
		--cap-drop=ALL \
		--security-opt=no-new-privileges:true \
		--publish 127.0.0.1:23231:23231 \
		--volume "$(CURDIR)/data:/soft-serve" \
		--env SOFT_SERVE_INITIAL_ADMIN_KEYS="$(SOFT_SERVE_INITIAL_ADMIN_KEYS)" \
		$(TEST_IMAGE_NAME)

clean:
	docker stop $(TEST_CONTAINER_NAME)
	rm -rf "$(CURDIR)/data"
	docker image rm $(TEST_IMAGE_NAME)

prune: clean
	docker image rm $(IMAGE_NAME)
	yes | docker container prune
	yes | docker builder prune --all

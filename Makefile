IMAGE_NAME = $(shell tofu output --raw soft_serve_image_name)
build_soft_serve:
	docker build soft-serve/docker -t $(IMAGE_NAME)
push_soft_serve:
	docker push $(IMAGE_NAME)

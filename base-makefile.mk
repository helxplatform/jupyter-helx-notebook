# Makefile for building a docker image.

# Thanks to  https://gist.github.com/mpneuried/0594963ad38e68917ef189b4e6a269db
# for a lot of this.

DATETIME := $(shell /bin/date "+%Y%m%d%H%M")
# get the latest commit hash in the short form
COMMIT_SHORT_HASH := $(shell git rev-parse --short HEAD)
COMMIT_DATETIME := $(shell git log -1 --format=%cd --date=format:"%Y%m%d%H%M")
# add the commit date/time
COMMIT_HASH_TAG := $(COMMIT_SHORT_HASH)-$(COMMIT_DATETIME)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

build: ## Build the image.
	docker build --pull \
		--platform=linux/amd64 . \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG} \
		-t ${APP_NAME}

build-nc: ## Build the image without caching.
	docker build --pull --no-cache \
		--platform=linux/amd64 . \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG} \
		-t ${APP_NAME}

build-with-logs: ## Build the image without caching.
	docker build --pull \
		--progress=plain \
		--platform=linux/amd64 . \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG} \
		-t ${APP_NAME}

run: ## Run container on port configured in `config.env`
	docker run -i -t --rm --env-file=./run.env -u $(UID):$(GID) \
	  -v $(PWD)/host:/host -p=$(FORWARDING_PORT):$(CONTAINER_PORT) \
	  --name="$(APP_NAME)" $(APP_NAME) $(ENTRYPOINT)

up: build run ## Run container on port configured in `config.env` (Alias to run)

stop: ## Stop and remove a running container
	docker stop $(APP_NAME); docker rm $(APP_NAME)

release: build-nc publish ## Make a release by building and publishing tagged containers to ECR

# Docker publish
publish: publish-latest publish-version ## Publish tags

publish-latest: tag-latest ## Publish the `latest` tagged container to ECR
	@echo 'publish latest to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):latest

publish-version: tag-version ## Publish the `{TAG}` tagged container to ECR
	@echo 'publish $(TAG) to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):$(TAG)

publish-short-hash: tag-short-hash ## Publish the short-hash tagged container to ECR
	@echo 'publish $(COMMIT_HASH_TAG) to $(IMAGE_REPO)'
	docker push $(IMAGE_REPO)/$(APP_NAME):$(COMMIT_HASH_TAG)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags

tag-latest: ## Generate container `latest` tag
	@echo 'create tag latest'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):latest

tag-version: ## Generate container `{TAG}` tag
	@echo 'create tag $(TAG)'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):$(TAG)

tag-short-hash: ## Generate container short-hash tag created from last commit or current datetime if tree is dirty
	@echo 'create tag $(COMMIT_HASH_TAG)'
	docker tag $(APP_NAME) $(IMAGE_REPO)/$(APP_NAME):$(COMMIT_HASH_TAG)

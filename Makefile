ALPINE_ELIXIR_FIPS ?= michaelmichalski/alpine-elixir-fips
ALPINE_FIPS ?= michaelmichalski/alpine-fips

ifndef ALPINE_VERSION
override ALPINE_VERSION=3.10
endif
ifndef ERLANG_VERSION
override ERLANG_VERSION=22.2
endif
ifndef ELIXIR_VERSION
override ELIXIR_VERSION="v1.9.1"
endif

alpine:
	docker build --squash --force-rm --target alpine-fips --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(ALPINE_FIPS):latest -t $(ALPINE_FIPS):$(ALPINE_VERSION) .

alpine-elixir:
	docker build --squash --force-rm --target alpine-elixir-fips --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(ALPINE_ELIXIR_FIPS):latest -t $(ALPINE_ELIXIR_FIPS):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION) .

distroless:
	docker build --squash --force-rm --target alpine-fips --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ALPINE_VERSION=$(ALPINE_VERSION) -t $(ALPINE_FIPS):latest -t $(ALPINE_FIPS):$(ALPINE_VERSION) .

all: alpine alpine-elixir ## Build the Docker image

clean: ## Clean up generated images
	@docker rmi --force $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(MIN_VERSION) $(IMAGE_NAME):$(MAJ_VERSION) $(IMAGE_NAME):latest

rebuild: clean all

push:
	docker push $(ALPINE_FIPS):latest
	docker push $(ALPINE_FIPS):$(ALPINE_VERSION)
	docker push $(ALPINE_ELIXIR_FIPS):latest
	docker push $(ALPINE_ELIXIR_FIPS):$(ALPINE_VERSION)-$(ERLANG_VERSION)-$(ELIXIR_VERSION)

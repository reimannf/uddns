NAME   = uddns
PKG    = github.com/reimannf/$(NAME)

PREFIX        := /usr
OS            = $(shell uname -s)
GO            := GOBIN=$(CURDIR)/build go
GO_BUILDFLAGS :=
GO_LDFLAGS    := -s -w

# dependencies that are used by the build&test process, these need to be installed in the
# global Go env and not in the vendor sub-tree
DEPEND=github.com/Masterminds/glide \
       github.com/golang/lint/golint

M = $(shell printf "\033[34;1m▶\033[0m")

# This target uses the incremental rebuild capabilities of the Go compiler to speed things up.
# If no source files have changed, `go install` exits quickly without doing anything.
build: FORCE ;$(info $(M) Building)
	$(GO) install $(GO_BUILDFLAGS) -ldflags '$(GO_LDFLAGS)' '$(PKG)'

# Installing build dependencies. You will need to run this once manually when you clone the repo
depend: ;$(info $(M) Install dependencies)
	go get -v $(DEPEND)
	glide install

clean: ;$(info $(M) Cleaning up)
	rm -rf build/*

install: FORCE all
	install -D -m 0755 build/$(NAME) "$(DESTDIR)$(PREFIX)/bin/limes"

check: ;$(info $(M) Static checks)
	@if gofmt -l . | egrep -v ^vendor/ | grep .go; then \
	  echo "^- Repo contains improperly formatted go files; run gofmt -w *.go" && exit 1; \
	  else echo "All .go files formatted correctly"; fi
	go tool vet -v -composites=false *.go
	for pkg in $$(go list ./... | grep -v /vendor/); do $(GO) vet -v $$pkg; done
	for pkg in $$(go list ./... | grep -v /vendor/); do golint $$pkg; done

build/docker.tar: ;$(info $(M) Building static)
ifeq ($(OS), Darwin)
	docker run --rm -v $(CURDIR):"/go/$(PKG)" -w "/go/$(PKG)" -e "GOPATH=/go" golang:1.8 env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-s -w -linkmode external -extldflags -static' -o build/$(NAME)_linux_amd64
else
	env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-s -w -linkmode external -extldflags -static' -o build/$(NAME)_linux_amd64
endif
	tar cf - build/$(NAME)_linux_amd64 > build/docker.tar

DOCKER       := docker
DOCKER_IMAGE := reimannf/$(NAME)
DOCKER_TAG   := latest

docker: build/docker.tar; $(info $(M) Building Docker)
	$(DOCKER) build -t "$(DOCKER_IMAGE):$(DOCKER_TAG)" .

.PHONY: FORCE
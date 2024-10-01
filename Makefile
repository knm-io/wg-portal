# Go parameters
GOCMD=go
MODULENAME=github.com/h44z/wg-portal
GOFILES:=$(shell go list ./... | grep -v /vendor/)
BUILDDIR=dist
BINARIES=$(subst cmd/,,$(wildcard cmd/*))
IMAGE=h44z/wg-portal
NPMCMD=npm

all: help

.PHONY: help
help:
	@echo "Usage:"
	@sed -n 's/^#>//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'  # user commands (#>)
	@echo ""
	@echo "Advanced commands:"
	@sed -n 's/^#<//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'  # internal commands (#<)

########################################################################################
##
## DEVELOPER / USER TARGETS
##
########################################################################################

#> codegen: Re-generate autogenerated files (like API docs)
.PHONY: codegen
codegen: $(SUBDIRS)
	cd internal; swag init --propertyStrategy pascalcase --parseInternal --generalInfo server/api.go --output server/docs/
	$(GOCMD) fmt internal/server/docs/docs.go

#> update: Update all dependencies
.PHONY: update
update:
	@ $(GOCMD) get -u ./...
	@ $(GOCMD) mod tidy

#> format: Re-format the code
.PHONY: format
format:
	@echo "Formatting code..."
	@ $(GOCMD) fmt $(GOFILES)

########################################################################################
##
## TESTING / CODE QUALITY TARGETS
##
########################################################################################

#> test: Run all kinds of tests, except for integration tests
.PHONY: test
test: test-vet test-race

#< test-vet: Static code analysis
.PHONY: test-vet
test-vet: build-dependencies
	@$(GOCMD) vet $(GOFILES)

#< test-race: Race condition test
.PHONY: test-race
test-race: build-dependencies
	@$(GOCMD) test -race -short $(GOFILES)

########################################################################################
##
## CI TARGETS
##
########################################################################################

#< clean: Delete all generated executables and test files
.PHONY: clean
clean:
	@rm -rf $(BUILDDIR)

#< build: Build all executables (architecture depends on build system)
.PHONY: build
build: build-dependencies
	CGO_ENABLED=0 $(GOCMD) build -o $(BUILDDIR)/wg-portal \
	 -ldflags "-w -s -extldflags \"-static\" -X 'github.com/h44z/wg-portal/internal/server.Version=${ENV_BUILD_IDENTIFIER}-${ENV_BUILD_VERSION}'" \
	 -tags netgo \
	 cmd/wg-portal/main.go

#< build-amd64: Build all executables for AMD64
.PHONY: build-amd64
build-amd64: build-dependencies
	CGO_ENABLED=0 $(GOCMD) build -o $(BUILDDIR)/wg-portal-amd64 \
	 -ldflags "-w -s -extldflags \"-static\" -X 'github.com/h44z/wg-portal/internal/server.Version=${ENV_BUILD_IDENTIFIER}-${ENV_BUILD_VERSION}'" \
	 -tags netgo \
	 cmd/wg-portal/main.go

#< build-arm64: Build all executables for ARM64
.PHONY: build-arm64
build-arm64: build-dependencies
	CGO_ENABLED=0 CC=aarch64-linux-gnu-gcc GOOS=linux GOARCH=arm64 $(GOCMD) build -o $(BUILDDIR)/wg-portal-arm64 \
	 -ldflags "-w -s -extldflags \"-static\" -X 'github.com/h44z/wg-portal/internal/server.Version=${ENV_BUILD_IDENTIFIER}-${ENV_BUILD_VERSION}'" \
	 -tags netgo \
	 cmd/wg-portal/main.go

#< build-arm: Build all executables for ARM32
.PHONY: build-arm
build-arm: build-dependencies
	CGO_ENABLED=0 CC=arm-linux-gnueabi-gcc GOOS=linux GOARCH=arm GOARM=7 $(GOCMD) build -o $(BUILDDIR)/wg-portal-arm \
	 -ldflags "-w -s -extldflags \"-static\" -X 'github.com/h44z/wg-portal/internal/server.Version=${ENV_BUILD_IDENTIFIER}-${ENV_BUILD_VERSION}'" \
	 -tags netgo \
	 cmd/wg-portal/main.go

#< build-dependencies: Generate the output directory for compiled executables and download dependencies
.PHONY: build-dependencies
build-dependencies:
	@$(GOCMD) mod download -x
	@mkdir -p $(BUILDDIR)
	cp scripts/wg-portal.service $(BUILDDIR)

#< frontend: Build Vue.js frontend
frontend: frontend-dependencies
	cd frontend; $(NPMCMD) run build

#< frontend-dependencies: Generate the output directory for compiled executables and download frontend dependencies
.PHONY: frontend-dependencies
frontend-dependencies:
	@mkdir -p $(BUILDDIR)
	cd frontend; $(NPMCMD) install

#< build-docker: Build a docker image on the current host system
.PHONY: build-docker
build-docker:
	docker build --progress=plain \
	--build-arg BUILD_IDENTIFIER=${ENV_BUILD_IDENTIFIER} --build-arg BUILD_VERSION=${ENV_BUILD_VERSION} \
 	--build-arg TARGETPLATFORM=unknown . \
	-t h44z/wg-portal:local

#< helm-docs: Generate the helm chart documentation
.PHONY: helm-docs
helm-docs:
	docker run --rm --volume "${PWD}/deploy:/helm-docs" -u "$$(id -u)" jnorwood/helm-docs -s file

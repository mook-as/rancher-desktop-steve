DASHBOARD_VERSION := v2.11.1.rd4
DASHBOARD_CHECKSUM := 22839af7ae78f1c9dbf2559a0be8a6cd355426b6dc31795ce8fd86a4257d4d509778b07b4cee36088c0c5ec072e6c09e2d8e7bbb4d070d0b70cd2c158abfe668

PLATFORMS := darwin-amd64 darwin-arm64 linux-amd64 linux-arm64 windows-amd64

.DELETE_ON_ERROR:

# Default target: build the checksum file, which requires all the tarballs.
release/steve.sha512sum: $(foreach p,$(PLATFORMS),release/steve-$(p).tar.gz)
	cd $(@D) && sha512sum $(^F) > "$(@F)"

# Determine the executable suffix based on platform.
EXE_SUFFIX = $(if $(findstring windows,$(1)),.exe)

# Define explicit rules for each tarball, to ensure it does not conflict with
# the wildcard rule for executables.
define PLATFORM_RULE
release/steve-$(1).tar.gz: release/steve-$(1)$(call EXE_SUFFIX,$(1))
	tar -czf "$$@" -C "$$(@D)" "$$(+F)"
endef
$(foreach p,$(PLATFORMS),$(eval $(call PLATFORM_RULE,$(p))))

# Define implicit rules for each executable; requires dashboard.
GOLANG_SOURCES := $(shell find pkg -name '*.go') main.go go.mod go.sum
# For release/steve-$(GOOS)-$(GOOARCH)
GOOS = "$(firstword $(subst -, ,$*))"
GOARCH = "$(lastword $(subst -, ,$(*:.exe=)))"
release/steve-%: dashboard/index.html $(GOLANG_SOURCES) $(MAKEFILE_LIST)
	mkdir -p "$(@D)"
	env GOOS=$(GOOS) GOARCH=$(GOARCH) go build  -ldflags '-s -w' -trimpath -o "$@"

# The dashboard requires the downloaded dashboard archive.
dashboard/index.html: dashboard.tgz
	mkdir -p "$(@D)"
	tar -xzf "$<" -C "$(@D)"

# The dashboard archive is downloaded.
dashboard.tgz:
	wget -O "$@" "https://github.com/rancher-sandbox/rancher-desktop-dashboard/releases/download/desktop-$(DASHBOARD_VERSION)/rancher-dashboard-desktop-embed.tar.gz"
	echo "$(DASHBOARD_CHECKSUM)  dashboard.tgz" | sha512sum -c -

.PHONY: clean
clean:
	rm -rf release dashboard dashboard.tgz

# Maintenance tasks for this overlay. Run `make` (or `make help`) for the list.
#
# Runs as a normal user, on this checkout (not on /var/db/repos/<repo>, which
# portage syncs from GitHub). PKG=<category/name> limits `manifest` to one
# package, e.g. `make manifest PKG=dev-util/ghidra`.

REPO := $(shell cat profiles/repo_name)
GENTOO_REPO := $(shell portageq get_repo_path / gentoo)

# Downloads go to portage's distfiles dir when we may write there (then emerge
# finds them), otherwise to a per-user cache.
SYSTEM_DISTDIR := $(shell portageq distdir)
DISTDIR ?= $(if $(shell test -w $(SYSTEM_DISTDIR) && echo yes),$(SYSTEM_DISTDIR),$(HOME)/.cache/distfiles)

PACKAGES := $(if $(PKG),$(PKG)/,$(sort $(dir $(wildcard */*/*.ebuild))))

# egencache must see this checkout as the repo, with gentoo as its master for
# the eclasses, instead of the synced copy that repos.conf points at.
define REPOS_CONF
[DEFAULT]
main-repo = gentoo
[gentoo]
location = $(GENTOO_REPO)
[$(REPO)]
location = $(CURDIR)
masters = gentoo
endef
export REPOS_CONF

.DEFAULT_GOAL := help
.PHONY: help all manifest metadata

help: ## Show this list of targets
	@awk 'BEGIN { FS = ":.*## " } \
		/^[a-zA-Z0-9_-]+:.*## / { printf "  %-10s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

all: manifest metadata ## Update all Manifests, then the metadata cache

# Any one ebuild of a package will do: `ebuild … manifest` writes the
# package's whole Manifest, covering all of its versions.
manifest: ## Regenerate package Manifests (fetches distfiles to DISTDIR)
	@mkdir -p $(DISTDIR)
	@for pkg in $(PACKAGES); do \
		echo ">>> $$pkg"; \
		set -- $$pkg*.ebuild; \
		DISTDIR=$(DISTDIR) ebuild "$$1" manifest || exit 1; \
	done

# --cache-dir: the default /var/cache/edb/dep is only writable by root.
metadata: ## Regenerate metadata/md5-cache from the ebuilds
	@mkdir -p $(HOME)/.cache/egencache
	egencache --update --repo=$(REPO) --repositories-configuration="$$REPOS_CONF" \
		--cache-dir=$(HOME)/.cache/egencache --jobs=$(shell nproc)

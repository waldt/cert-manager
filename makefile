VERSION ?= $(shell git describe --tags)

sync: submodule-update
	cd upstream/cert-manager &&	git checkout ${VERSION}
	cp -vr upstream/cert-manager/deploy/charts/cert-manager/ stable/cert-manager/

submodule-update:
	git submodule update --init --remote upstream/cert-manager

submodule:
	git submodule add --name upstream/cert-manager https://github.com/jetstack/cert-manager

PATCHES := $(sort $(wildcard *.patch))


makepatch:
	git add -A stable/cert-manager
	git diff --cached > next.patch

patch: $(PATCHES)

%.patch: $(shell find stable/cert-manager -type f)
	git apply $@
	touch $@

${HOME}/.helm/repository/local:
	helm init -c

helm-init: ${HOME}/.helm/repository/local

package: helm-init
	helm package stable/cert-manager --version ${VERSION} --app-version ${VERSION}
	mv -v cert-manager-${VERSION}.tgz docs

repo-index:
	helm repo index docs --url https://infobloxopen.github.io/cert-manager/

git-config:
	@if ! git config user.email ; then\
		git config user.email "dwells@infoblox.com"; \
	fi
	@if ! git config user.name ; then\
		git config user.name "Github Actions"; \
	fi

update-index: git-config package repo-index
	if ! git tag --contains ${VERSION} ; then\
		git add .; \
		git commit -m "updated index for ${VERSION} fixes #${TICKET}"; \
		git tag -a ${VERSION} -m "${VERSION} release"; \
		git push origin master --tags; \
	fi

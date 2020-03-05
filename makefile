VERSION ?= $(shell git describe --tags)

sync:
	cd upstream/cert-manager &&	git checkout ${VERSION}
	cp -vr upstream/cert-manager/deploy/charts/cert-manager/ stable/cert-manager/

submodule-update:
	git submodule update --remote upstream/cert-manager

submodule:
	git submodule add --name upstream/cert-manager https://github.com/jetstack/cert-manager

PATCHS := 01-crds.patch

makepatch:
	git add -A stable/cert-manager
	git diff --cached > 01-crds.patch

patch: $(PATCHS)

%.patch: $(shell find stable/cert-manager -type f)
	git apply $@
	touch $@

package:
	helm package stable/cert-manager --version ${VERSION}
	mv -v cert-manager-${VERSION}.tgz docs

repo-index:
	helm repo index docs --url https://infobloxopen.github.io/cert-manager/

update-index:
	git commit -am "updated index for ${VERSION}"
	git push origin master
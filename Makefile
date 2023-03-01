RUNTIME := $(shell command -v podman || command -v docker)
RUNTIME := $(shell basename $(RUNTIME))
ifeq ($(RUNTIME),)
$(error Unable to run without a container runtime (podman, docker) available)
endif

REGISTRY := ghcr.io
REPOSITORY := redhat-manufacturing/edge-lab-ansible

# This should resolve to every file in the collection. If we add any kind of python plugin
# at a later date, we should ensure we update SRC to glob for those files as well. Doing this
# makes it so that the Makefile will rebuild only what it needs to every time there's a change.
SRC_YAML := $(wildcard collection/roles/*/*/*.yml collection/roles/*/*/*/*.yml collection/roles/*/*/*/*/*.yml)
SRC := collection/requirements.txt collection/bindep.txt $(SRC_YAML) $(wildcard collection/roles/*/*/*.j2)

all: ee
.PHONY: all

##############################################################################
#                             DEV ENVIRONMENT                                #
##############################################################################
venv/bin/pip:
	python3 -m venv venv
	venv/bin/pip install --upgrade pip setuptools wheel

.pip-prereqs: venv/bin/pip requirements-devel.txt
	venv/bin/pip install -r requirements-devel.txt
	touch .pip-prereqs

venv/bin/yasha: .pip-prereqs
venv/bin/ansible-galaxy: .pip-prereqs
venv/bin/ansible-builder: .pip-prereqs
venv/bin/yamllint: .pip-prereqs
venv/bin/ansible-lint: .pip-prereqs

clean-prereqs:
	rm -rf venv .pip-prereqs
.PHONY: clean-prereqs

prereqs: .pip-prereqs
.PHONY: prereqs

lint: venv/bin/yamllint venv/bin/ansible-lint $(SRC_YAML)
	venv/bin/yamllint $(SRC_YAML)
	venv/bin/yamllint $(wildcard playbooks/*.yml)
	venv/bin/ansible-lint $(SRC_YAML)
	# Unable to do ansible-lint on playbooks due to collection/EE scoping
.PHONY: lint

##############################################################################
#                               COLLECTION                                   #
##############################################################################
VERSION: .pip-prereqs $(SRC)
	@venv/bin/python -m setuptools_scm 2>/dev/null | gawk -F+ '{gsub(/\.dev/, "-dev", $$1); gsub(/^[0-9]\.[0-9]-/, "&.0", $$1); gsub(/-\.0dev/, ".0-dev", $$1); print $$1}' > VERSION

collection/galaxy.yml: venv/bin/yasha VERSION
	-rm -f collection/galaxy.yml
	venv/bin/yasha --VERSION=$$(cat VERSION) collection/galaxy.yml.j2

.collection: venv/bin/ansible-galaxy collection/galaxy.yml
	$(MAKE) lint
	venv/bin/ansible-galaxy collection build -v collection --force
	touch .collection

collection: .collection
.PHONY: collection

##############################################################################
#                          EXECUTION ENVIRONMENT                             #
##############################################################################
.ee-built: venv/bin/ansible-builder .collection $(wildcard execution-environment/Containerfile*) execution-environment/requirements.yml execution-environment/execution-environment.yml
	cp edge_lab-infra-$$(cat VERSION).tar.gz execution-environment/edge_lab-infra-latest.tar.gz
	$(RUNTIME) build execution-environment -f Containerfile.builder -t extended-builder-image
	$(RUNTIME) build execution-environment -f Containerfile.base -t extended-base-image
	cd execution-environment \
		&& ../venv/bin/ansible-builder build -v 3 --container-runtime $(RUNTIME) -t localhost/edge_lab-infra:latest
	$(RUNTIME) tag localhost/edge_lab-infra:latest $(REGISTRY)/$(REPOSITORY):$$(cat VERSION)
	$(RUNTIME) tag localhost/edge_lab-infra:latest $(REGISTRY)/$(REPOSITORY):latest
	touch .ee-built

.ee-published: .ee-built
	$(RUNTIME) push $(REGISTRY)/$(REPOSITORY):$$(cat VERSION)
	$(RUNTIME) push $(REGISTRY)/$(REPOSITORY):latest
	touch .ee-published

ee: .ee-built
.PHONY: ee

publish: .ee-published
.PHONY: publish

##############################################################################
#                                 CLEANUP                                    #
##############################################################################
clean:
	rm -rf edge_lab-*.tar.gz .collection collection/galaxy.yml VERSION
.PHONY: clean

realclean: clean clean-prereqs
	-rm -rf .ee-built execution-environment/{context,edge_lab-*.tar.gz}
	-$(RUNTIME) rmi extended-builder-image
	-$(RUNTIME) rmi extended-base-image
	-$(RUNTIME) rmi edge_lab-infra:$$(cat VERSION)
	-rm -f VERSION
.PHONY: realclean

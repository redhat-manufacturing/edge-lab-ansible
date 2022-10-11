RUNTIME = podman
ANSIBLE_TAGS =
ANSIBLE_SKIP_TAGS =

SRC := collection/requirements.txt collection/galaxy.yml $(wildcard collection/roles/*/*/*.yml collection/roles/*/*/*.j2)
VERSION

all: collection
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

clean-prereqs:
	rm -rf venv
.PHONY: clean-prereqs

prereqs: venv/bin/yasha venv/bin/ansible-galaxy venv/bin/ansible-builder venv/bin/setuptools-scm
.PHONY: prereqs

##############################################################################
#                               COLLECTION                                   #
##############################################################################
VERSION: .pip-prereqs $(SRC)
	@venv/bin/python -m setuptools_scm 2>/dev/null > VERSION

collection/galaxy.yml: .pip-prereqs VERSION
	-rm -f collection/galaxy.yml
	venv/bin/yasha --VERSION=$(shell cat VERSION) collection/galaxy.yml.j2

.collection: collection/galaxy.yml
	venv/bin/ansible-galaxy collection build -v collection
	touch .collection

## TODO: FINISH BELOW
##############################################################################
#                          EXECUTION ENVIRONMENT                             #
##############################################################################
.ee-built: .collection
	cp  execution-environment/jharmison_redhat-oc_mirror_e2e-latest.tar.gz
	cd execution-environment \
	  && $(RUNTIME) build . -f Containerfile.builder -t extended-builder-image \
	  && $(RUNTIME) build . -f Containerfile.base -t extended-base-image \
	  && ../.venv/bin/ansible-builder build -v 3 --container-runtime $(RUNTIME) -t oc-mirror-e2e:$(VERSION)
	touch .ee-built

ee: .ee-built

.ee-published: .ee-built
	$(RUNTIME) tag oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):$(VERSION)
	$(RUNTIME) push $(PUSH_IMAGE):$(VERSION)
	$(RUNTIME) tag oc-mirror-e2e:$(VERSION) $(PUSH_IMAGE):latest
	$(RUNTIME) push $(PUSH_IMAGE):latest
	touch .ee-published

ee-publish: .ee-published

##############################################################################
#                               RUN CONTENT                                  #
##############################################################################
run: .ee-built
	ANSIBLE_TAGS=$(ANSIBLE_TAGS) ANSIBLE_SKIP_TAGS=$(ANSIBLE_SKIP_TAGS) EE_VERSION=$(VERSION) RUNTIME=$(RUNTIME) ANSIBLE_EXTRA_VARS_FILES="$(ANSIBLE_SCENARIO_VARS)" example/run.sh $(ANSIBLE_PLAYBOOKS)
destroy: .ee-built
	ANSIBLE_TAGS=$(ANSIBLE_TAGS) ANSIBLE_SKIP_TAGS=$(ANSIBLE_SKIP_TAGS) EE_VERSION=$(VERSION) RUNTIME=$(RUNTIME) ANSIBLE_EXTRA_VARS_FILES="$(ANSIBLE_SCENARIO_VARS)" example/run.sh delete
exec: .ee-built
	ANSIBLE_EE_SHELL=true ANSIBLE_TAGS=$(ANSIBLE_TAGS) ANSIBLE_SKIP_TAGS=$(ANSIBLE_SKIP_TAGS) EE_VERSION=$(VERSION) RUNTIME=$(RUNTIME) ANSIBLE_EXTRA_VARS_FILES="$(ANSIBLE_SCENARIO_VARS)" example/run.sh

##############################################################################
#                                 CLEANUP                                    #
##############################################################################
clean:
	rm -rf jharmison_redhat-oc_mirror_e2e-*.tar.gz collection/galaxy.yml
realclean: clean clean-prereqs
	podman unshare rm -rf example/output/*
	rm -rf example/artifacts/* .pip-prereqs .collection-published .ee-built .ee-published
	-$(RUNTIME) rmi extended-builder-image
	-$(RUNTIME) rmi extended-base-image
	-$(RUNTIME) rmi oc-mirror-e2e:$(VERSION)

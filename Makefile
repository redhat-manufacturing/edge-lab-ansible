RUNTIME = podman

SRC := collection/requirements.txt collection/bindep.txt $(wildcard collection/roles/*/*/*.yml collection/roles/*/*/*.j2)

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

clean-prereqs:
	rm -rf venv .pip-prereqs
.PHONY: clean-prereqs

prereqs: venv/bin/yasha venv/bin/ansible-galaxy venv/bin/ansible-builder
.PHONY: prereqs

##############################################################################
#                               COLLECTION                                   #
##############################################################################
VERSION: .pip-prereqs $(SRC)
	@venv/bin/python -m setuptools_scm 2>/dev/null | sed -e 's/\.\(dev[^+]\+\).*$$/-\1/' -e 's/^\([0-9]\.[0-9]\)-/\1.0-/' > VERSION

collection/galaxy.yml: .pip-prereqs VERSION
	-rm -f collection/galaxy.yml
	venv/bin/yasha --VERSION=$$(cat VERSION) collection/galaxy.yml.j2

.collection: collection/galaxy.yml
	venv/bin/ansible-galaxy collection build -v collection
	touch .collection

collection: .collection
.PHONY: collection

##############################################################################
#                          EXECUTION ENVIRONMENT                             #
##############################################################################
.ee-built: .collection
	cp osdu_lab-infra-$$(cat VERSION).tar.gz execution-environment/osdu_lab-infra-latest.tar.gz
	$(RUNTIME) build execution-environment -f Containerfile.builder -t extended-builder-image
	$(RUNTIME) build execution-environment -f Containerfile.base -t extended-base-image
	cd execution-environment \
	  && ../venv/bin/ansible-builder build -v 3 --container-runtime $(RUNTIME) -t osdu_lab-infra:$$(cat ../VERSION)
	podman tag localhost/osdu_lab-infra:$$(cat VERSION) localhost/osdu_lab-infra:latest
	touch .ee-built

ee: .ee-built
.PHONY: ee

##############################################################################
#                                 CLEANUP                                    #
##############################################################################
clean:
	rm -rf osdu_lab-infra-*.tar.gz .collection collection/galaxy.yml
.PHONY: clean

realclean: clean clean-prereqs
	rm -rf .ee-built
	-$(RUNTIME) rmi extended-builder-image
	-$(RUNTIME) rmi extended-base-image
	-$(RUNTIME) rmi osdu_lab-infra:$$(cat VERSION)
	-rm -f VERSION
.PHONY: realclean

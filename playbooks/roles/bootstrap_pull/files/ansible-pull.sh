#!/bin/bash -i

set -exuo pipefail

run_playbook() {
    ansible-navigator exec -- ansible-pull -U ssh://git@github.com/redhat-manufacturing/osdu-lab-ansible.git --accept-host-key --limit "$AAP_INVENTORY_HOST" "$@"
}

for playbook in $(echo "$AAP_PLAYBOOKS" | tr ',' ' '); do
    run_playbook "$playbook" "$@" ${ANSIBLE_PULL_EXTRA_ARGS}
done

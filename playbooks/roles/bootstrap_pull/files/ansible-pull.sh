#!/bin/bash

set -exuo pipefail

run_playbook() {
    ansible-navigator exec -- ansible-pull -U ssh://git@github.com/redhat-manufacturing/osdu-lab-ansible.git --accept-host-key --limit "$AAP_INVENTORY_HOST" "$@" -e ansible_host=127.0.0.1
}

for playbook in $(echo "$AAP_PLAYBOOKS" | tr ',' ' '); do
    run_playbook "$playbook"
done

#!/bin/bash -i

set -exo pipefail

RUNTIME="${RUNTIME:-podman}"
runtime_args=(
    --authfile "$AAP_EE_AUTHFILE"
    --rm
    -it
    --privileged
    --security-opt=label=disable
    -e 'ANSIBLE_*'
    -e 'AAP_*'
    -v /root/.ssh:/home/runner/.ssh
    -v /root/.ssh:/root/.ssh
    -v "$ANSIBLE_PULL_PATH_REPO:/runner/project"
    -v "$ANSIBLE_VAULT_PASSWORD_FILE:$ANSIBLE_VAULT_PASSWORD_FILE"
    --name=ansible-pull
)

run_playbook() {
    # shellcheck disable=SC2086
    ${RUNTIME} run "${runtime_args[@]}" ${ANSIBLE_PULL_EXTRA_ARGS} -e "RUNNER_PLAYBOOK=$1" "${AAP_EE_IMAGE}"
}

update_project() {
    keyscan='if [ ! -n "$(grep "^github.com" ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi'
    if [ -d "$ANSIBLE_PULL_PATH_REPO/.git" ]; then
        script="$keyscan ; cd /runner/project && git checkout ${ANSIBLE_PULL_CHECKOUT} && git pull"
    else
        mkdir -p "$ANSIBLE_PULL_PATH_REPO"
        script="$keyscan ; cd /runner/project && git clone -b ${ANSIBLE_PULL_CHECKOUT} --depth=1 --recurse-submodules ${ANSIBLE_PULL_REPO} ."
    fi
    ${RUNTIME} run --pull always "${runtime_args[@]}" --entrypoint bash "${AAP_EE_IMAGE}" -c "${script}"
}

update_project

if [ -d "$ANSIBLE_PULL_PATH_REPO/inventory" ]; then
    runtime_args+=(
        -v "$ANSIBLE_PULL_PATH_REPO/inventory:/runner/inventory"
    )
fi

cmdline="$(mktemp)"
printf -- '--limit %s ' "$AAP_INVENTORY_HOST" > "$cmdline"
runtime_args+=(
    -v "$cmdline:/runner/env/cmdline"
)

for playbook in $(echo "$AAP_PLAYBOOKS" | tr ',' ' '); do
    run_playbook "$playbook" "$@"
done

rm -f "$cmdline"

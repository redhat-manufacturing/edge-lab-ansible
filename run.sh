#!/bin/bash

set -e

cd "$(dirname "$(realpath "$0")")"

bin_prereqs=(
    python3
    make
)

python_prereqs=(
    pip
)

missing_prereqs=false

for prereq in "${bin_prereqs[@]}"; do
    if ! command -v "$prereq" &>/dev/null; then
        echo "Unable to find $prereq in \$PATH. Please install it (via dnf)." >&2
        missing_prereqs=true
    fi
done

read -ra missing_python_prereqs <<< "$(echo "${python_prereqs[*]}" | python3 -c 'import sys; import pkg_resources; prereqs=sys.stdin.read().split(); pkgs=[pkg.key for pkg in pkg_resources.working_set]; [print(pkg) for pkg in prereqs if pkg not in pkgs]' 2>/dev/null)"

for prereq in "${missing_python_prereqs[@]}"; do
    echo "Unable to find $prereq in Python libraries. Please install it (via either pip or yum/dnf)." >&2
    missing_prereqs=true
done

if $missing_prereqs; then
    exit 1
fi

if [ -z "${ANSIBLE_VAULT_PASSWORD}" ]; then
    echo "You should export the vault password as ANSIBLE_VAULT_PASSWORD (with a leading space to prevent it entering history)." >&2
    read -rsn1 -p 'Press any key to continue.' _; echo
fi

make

playbook="playbooks/$1"
shift
if [ -e "$playbook.yml" ]; then
    playbook="$playbook.yml"
elif [ -e "$playbook" ]; then
    true
else
    echo "Unable to find playbook: $playbook" >&2
    exit 1
fi

venv/bin/ansible-navigator run "$playbook" "${@}"

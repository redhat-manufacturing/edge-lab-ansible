# OSDU lab Info

This repository is used to track / automate the assests in the OSDU Lab.

## Quickstart

```
# install python, pip, virtualenv, and make
sudo yum -y install python3 python3-pip python3-virtualenv make

# export the vault pass (NOTE THE LEADING SPACE)
 export ANSIBLE_VAULT_PASSWORD='the-actual-vault-pass'

# log in to the Red Hat Registry to be able to use an official EE base image
# best practice is to use a service account: https://access.redhat.com/terms-based-registry/#/
podman login registry.redhat.io
# OR
docker login registry.redhat.io

# premake the EE if you like
make

# ensure that your ssh-agent has your SSH key for connecting to bastion.edgelab.online
ssh-add -L

# ONLY IF YOU NEED TO: start the ssh-agent and/or add the appropriate key
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa   # or whatever the path to your keys is
```

## Playbooks

Run a playbook using run.sh to ensure the EE is up to date with any collection changes you've made and leverage ansible-navigator to run a playbook in the EE with the environment pre-prepped:

```
./run.sh ping.yml --limit bastion_public
```

The first argument to run.sh is a playbook in the `playbooks` directory. It can be specified with or without a `.yml` extension. All remaining arguments are passed after the playbook name directly to `ansible-navigator run`, which passes them directly to `ansible-playbook` - meaning any arguments to `run.sh` should be exactly as you're used to running them with `ansible-playbook` (as long as the playbook comes first).

## Running playbooks from the repo on an endpoint continuously in pull mode

Ensure that the things you'd like per group or host are configured in the following variables:

```yaml
ee_registry: registry.jharmison.com # the registry where you pushed the built EE collection
ee_repo: osdu-lab/infra # the container image repo in that registry
ee_tag: latest # the tag you'd like to follow

config_setup_dir: /etc/osdu-lab # the location you'd like to stage things like secrets, ssh keys, etc. on the endpoint (root-only readable)

ee_pull_user: puller # the user that can pull the EE image
ee_pull_password: <whatever> # the password for that user

# the playbooks you want the host to run regularly on itself
ansible_pull_playbooks:
- playbooks/configure_ssh.yml

# the repo you want tracked
ansible_pull_repo: ssh://git@github.com/redhat-manufacturing/osdu-lab-ansible.git
# the branch/tag/etc. you want tracked
ansible_pull_checkout: main

# the location to pull to
ansible_pull_path: /var/lib/osdu-lab
```

Ensure that you follow all other steps for leveraging the `run.sh` script (like the exported vault password) and run the following:

```sh
./run.sh setup.yml --limit <host or group> -e vault_password="${ANSIBLE_VAULT_PASSWORD}"
```

## Adhoc Commands

```
. venv/bin/activate

# bastion-public
ansible bastion_public -m raw -a 'uptime; uname -a'

# scan xcc/ipmi
ansible se350_bmc -m raw -a 'led'

# infra network scan
nmap -sn 10.1.{2,5}.*
```

## Topics

- [Hardening External VMs](docs/HARDENING.md)
- [Network](docs/NETWORK.md)
- [VPN](docs/VPN.md)

## Other Links

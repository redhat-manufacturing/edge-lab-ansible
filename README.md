# OSDU lab Info

This repository is used to track / automate the assests in the OSDU Lab.

## Quickstart

```
# install python, pip, virtualenv, and make
sudo yum -y install python3 python3-pip python3-virtualenv make

# save the vault pass
mkdir scratch
echo 'the-actual-vault-pass' > scratch/vault_pass.txt

# log in to the Red Hat Registry to be able to use an official EE base image
# best practice is to use a service account: https://access.redhat.com/terms-based-registry/#/
podman login registry.redhat.io
# OR
docker login registry.redhat.io

# premake the EE if you like
make

# ensure that your ssh-agent has your SSH key for connecting to osdu.coreapp.run
ssh-add -L

# ONLY IF YOU NEED TO: start the ssh-agent and/or add the appropriate key
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa   # or whatever the path to your keys is
```

## Playbooks

Run a playbook using run.sh to ensure the EE is up to date with any collection changes you've made and leverage ansible-navigator to run a playbook in the EE with the environment pre-prepped:

```
./run.sh playbooks/ping.yml --limit bastion_public
```

All arguments to run.sh are passed directly to `ansible-navigator run`, which passes them directly to `ansible-playbook` - meaning any arguments to `run.sh` should be exactly as you're used to running them with `ansible-playbook`.

## Pulling the execution environment and a playbook from the repo on an endpoint directly

Run all of the following as the root user (as this will be done via a systemd unit soon).

Enable the AAP repositories and install ansible-navigator:

```
dnf config-manager --set-enabled ansible-automation-platform-2.2-for-rhel-8-x86_64-rpms
dnf -y install ansible-navigator
```

Place the ansible-navigator configuration file to pull the execution environment somewhere:

```
ANSIBLE_NAVIGATOR_CONFIG=/etc/ansible-navigator.yml
cat << 'EOF' > $ANSIBLE_NAVIGATOR_CONFIG
ansible-navigator:
  execution-environment:
    container-options:
    - --privileged
    - --security-opt=label=disable
    enabled: true
    image: registry.jharmison.com/osdu-lab/infra:latest
  logging:
    append: true
    file: /var/log/ansible-navigator.log
  mode: stdout
  playbook-artifact:
    enable: false
EOF
```

Set up the vault password, log in to the registry, and ensure that an SSH key is configured to sign in to git:

```
echo 'the actual vault password' > /root/vault_pass.txt
podman login registry.jharmison.com  # a service account has been created that can pull from here, will be in vaulted secrets soon
mkdir -p ~/.ssh
cat << 'EOF' > ~/.ssh/id_rsa
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
[...]  # put an actual SSH key here
-----END OPENSSH PRIVATE KEY-----
EOF
chmod -R u=rwX,g=,o= ~/.ssh
```

Run ansible-navigator with the config and vault environment variables exported:

```
export ANSIBLE_NAVIGATOR_CONFIG
export ANSIBLE_VAULT_PASSWORD_FILE=/root/vault_pass.txt
# the following playbook is an example of how to use ansible-pull with ansible-navigator and not the thing I would expect you to run
ansible-navigator exec -- ansible-pull -U https://github.com/redhat-manufacturing/osdu-lab-ansible.git playbooks/ping.yml --limit bastion -c local
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

# dump network configs
ssh 10.1.2.1 "export terse" > files/router_cfg
ssh 10.1.2.2 "export terse" > files/switch_cfg

# clean network configs
egrep -v 'secret' files/router_cfg > files/router_cfg.cleaned
egrep -v 'secret' files/switch_cfg > files/switch_cfg.cleaned

# encrypt full config
ansible-vault encrypt files/*_cfg
```

## Topics

- [Hardening External VMs](docs/HARDENING.md)
- [Network](docs/NETWORK.md)
- [VPN](docs/VPN.md)

## Other Links

- [vbmc 4 vsphere](https://github.com/kurokobo/virtualbmc-for-vsphere)

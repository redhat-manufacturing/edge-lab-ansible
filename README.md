# OSDU lab Info

This repository is used to track / automate the assests in the OSDU Lab.

## Captured configs (cleaned of secrets)
- [router](files/router_cfg.cleaned)
- [switch](files/switch_cfg.cleaned)

## Quickstart
```
# install python
sudo yum -y install python3 python3-pip

# setup python virtual env
python3 -m venv venv --system-site-packages
. venv/bin/activate
pip install -U pip

# setup ansible
pip install -r requirements.txt

# setup ansible-vault
export ANSIBLE_VAULT_PASSWORD_FILE=$(pwd)/scratch/vault_pass.txt
```

## Adhoc Commands
```
# bastion-public
ansible bastion-public -m raw -a 'uptime; uname -a'

# scan xcc/ipmi
ansible se350_bmc -m raw -a 'version'

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

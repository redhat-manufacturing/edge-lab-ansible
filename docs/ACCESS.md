# Remote Access

Remote access info

## SSH Host Access

You can gain remote access to the lab via `ssh` public keys. 

You will need to generate an `ssh` [keypair](link_to_example)

```
ssh-keygen -t ed25519 -C "user@email"
```

Setup access to the following:

- User: `ansible`
- Host: `bastion.hou.edgelab.online`

```
ssh ansible@bastion.hou.edgelab.online
```

### Related files

`files/pubkeys/<username>`

Create this file to contain public keys for `user`

```
ssh-rsa AAAAB...== user@example.com
```

`inventory/group_vars/all/vars`

Add `username`'s public ssh key to the ssh group `redhat`

```
ssh_config_authorized_keys:
  redhat:
  - '{{ lookup("file", playbook_dir + "/../files/pubkeys/username") }}'
```

`collection/roles/setup_ssh/defaults/main.yml`

Defines default ssh desired group of public keys to install

```
desired_groups:
- redhat
```

`inventory/group_vars/bastion/vars`

Defines the user `ansible` is being configured on host `bastion`

```
ssh_config_users:
- ansible
```

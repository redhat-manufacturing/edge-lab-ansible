# Remote Access

Remote access info

## SSH Host Access

You can gain remote access to the lab via `ssh` public keys. 

You will need to generate an `ssh` [keypair](link_to_example)

```
ssh-keygen -t ed25519 -C "user@example.com"
```

Setup access to the following:

- User: `ansible`
- Host: `bastion.hou.edgelab.online`

```
ssh ansible@bastion.hou.edgelab.online
```

### Git related files

`files/pubkeys/<username>`

Create this file to contain public keys for `user`

```
ssh-rsa AAAAB...== user@example.com
```

`inventory/group_vars/all/vars`

Add (github) `username`'s public ssh key to the ssh group `example`

```
ssh_config_authorized_keys:
  example:
  - '{{ lookup("file", playbook_dir + "/../files/pubkeys/username") }}'
```

`collection/roles/setup_ssh/defaults/main.yml`

Defines default ssh desired group of public keys to install

```
desired_groups:
- redhat
- example
```

`inventory/group_vars/bastion/vars`

Defines the user `ansible` is being configured on host `bastion`

```
ssh_config_users:
- ansible
```

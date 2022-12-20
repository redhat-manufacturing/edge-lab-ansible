# GitLab Info

## Only allow root login via key auth

Update `/etc/ssh/sshd_config`

```
PermitRootLogin without-password
```

## Automated updates
```
dnf -y install dnf-automatic
systemctl enable --now dnf-automatic.timer
systemctl list-timers *dnf-*
```

Update `/etc/dnf/automatic.conf` with:

```
apply_updates = yes
emit_via = motd
```

## Install fail2ban
```
dnf -y install epel-release
dnf -y install fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

See [files/etc/fail2ban/jail.d](files/etc/fail2ban/jail.d) for examples.

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

## Install google authenticator
```
dnf -y install google-authenticator qrencode
```

Create `/etc/security/access-otp.conf` to allow SSH inside the lab without OTP.

```
+ : ALL : 127.0.0.0/8
+ : ALL : 10.0.0.0/8
+ : ALL : 192.168.0.0/16
- : (sudo) : ALL
- : ALL : ALL
```

Update `/etc/pam.d/sshd`
```
...
auth       substack     password-auth
auth       include      postlogin

# begin google-authenticator
auth       [success=1 default=ignore] pam_access.so accessfile=/etc/security/access-otp.conf
auth       required                   pam_google_authenticator.so secret=/home/${USER}/.ssh/.google_authenticator nullok no_increment_hotp [authtok_prompt=OTP Code: ]
# end google-authenticator
...
```

Update `/etc/ssh/sshd_config`
```
ChallengeResponseAuthentication yes
#AuthenticationMethods publickey,keyboard-interactive
```

Note: You will need to mv `~/.google_authenticator` to `~/.ssh/` to activate OTP (moved from default location because of selinux)

# Network Config

NOTICE!! All configs below are tentative and may not have been fully implemented

## Main Devices

UniFi

## Router Internet IPs

```
x.x.x.x/xx

Net: x.x.x.x
Gateway: x.x.x.x
```

## Public IPv4 IPs

```
x.x.x.x
```

### Currently Used Public IPv4 IPs

```
```

## Internal IPv4 IPs

IPv4 Networks

- 192.168.0.0/16
- 192.168.`[VLAN]`.0/24?

Example:

- VLAN: `10`
- Net: 192.168.`10`.0/24

### Used Internal IPv4 Networks

```
Network          | Assignment
192.168.1.0/24   | [ Reserved ]
192.168.2.0/24   | [ Reserved ]
192.168.10.0/24  | [ Out of Band Management ]
192.168.30.0/24  | [ Reserved ] - Retiring


Network         | Assignment   | Range
192.168.x.0/24  | Management   | 20-40
```

#!/usr/bin/env python3
"""Command generator for setting DHCP Option 119

This script converts the specified domain names to DHCP Option 119
(Domain Search Option) and prints commands for various DHCP servers.

USAGE:
  ./dhcp_option119.py DOMAIN ...

EXAMPLE:
  ./dhcp_option119.py apple.com google.com
"""

from __future__ import print_function
import sys

hexlist = []
for domain in sys.argv[1:]:
    for part in domain.split('.'):
        hexlist.append('%02x' % len(part))
        hexlist.extend(['%02x' % ord(char) for char in str.lower(part)])
    hexlist.append('00')

print("""
MikroTik RouterOS
-----------------
/ip dhcp-server option
add code=119 name=domain-search value=0x""", ''.join(hexlist), sep='')

print("""
Cisco IOS
---------
ip dhcp pool POOL_NAME
   option 119 hex """, ''.join([(".%s" % (x) if i and not i % 2 else x)
                                for i, x in enumerate(hexlist)]), sep='')

print("""
Windows DHCP Server
-------------------
netsh dhcp server V4 set optionvalue 119 BYTE """, ' '.join(hexlist), sep='')

print("""
Juniper SRX
------------
set access address-assignment pool POOL_NAME family inet \
dhcp-attributes option 119 hex-string """, ''.join(hexlist), sep='')

print("""
ZyXEL Keenetic
--------------
ip dhcp pool POOL_NAME option 119 hex """, ''.join(hexlist), sep='')

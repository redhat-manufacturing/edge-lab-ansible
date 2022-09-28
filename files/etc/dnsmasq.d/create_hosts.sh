#!/bin/sh
CONFIG='06-dhcp-*.conf'
DHCP_CFG=dnsmasq.dhcp

# setup dhcp
sed -n 's/^dhcp-host=//p' ${CONFIG} | awk -F, '{print $3 "\t" $2}' > hosts.dhcp

#!/bin/sh
/sbin/iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
/sbin/iptables -A FORWARD -i wlan0 -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i br0 -o wlan0 -j ACCEPT

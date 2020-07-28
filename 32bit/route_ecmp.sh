#!/bin/bash
if [ "`cat /etc/iproute2/rt_tables|grep hop`" == "" ]
then
  echo "200 hop0" >> /etc/iproute2/rt_tables
  echo "201 hop1" >> /etc/iproute2/rt_tables
  ip route add table hop0 default via 10.252.200.200
  ip route add table hop1 default via 10.252.200.201

  ip rule add fwmark 0xa table hop0
  ip rule add fwmark 0xb table hop1

  iptables -t mangle -N redirection
  iptables -t mangle -N RESTORE
  iptables -t mangle -N HOP0
  iptables -t mangle -N HOP1
  # floating ip 대역만
  iptables -t mangle -A PREROUTING -d 10.252.120.0/24 -j redirection
  # forward routing 만 통과하게끔
  iptables -t mangle -A OUTPUT -d 10.252.120.0/24 ! -o eth0 -j redirection

  iptables -t mangle -A RESTORE -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff
  iptables -t mangle -A RESTORE -j ACCEPT

  iptables -t mangle -A HOP0 -j MARK --set-xmark 0xa/0xffffffff
  iptables -t mangle -A HOP0 -j CONNMARK --save-mark --nfmask 0xffffffff --ctmask 0xffffffff
  iptables -t mangle -A HOP1 -j MARK --set-xmark 0xb/0xffffffff
  iptables -t mangle -A HOP1 -j CONNMARK --save-mark --nfmask 0xffffffff --ctmask 0xffffffff

  iptables -t mangle -A redirection -p tcp -m state --state RELATED,ESTABLISHED -j RESTORE
  iptables -t mangle -A redirection -p tcp -m state --state NEW -m statistic --mode nth --every 2 --packet 0 -j HOP0
  iptables -t mangle -A redirection -p tcp -m state --state NEW -m statistic --mode nth --every 2 --packet 1 -j HOP1
fi

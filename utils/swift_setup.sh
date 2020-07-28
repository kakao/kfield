#!/bin/bash -x

ip=$(ifconfig eth0 | grep 'inet addr' | cut -d':' -f2 | cut -d' ' -f1)
umount  -f -l /srv/node/disk
rm -rf /srv/node/disk
rm -f /srv/swift-disk
mkdir -p /srv/node/disk
truncate -s 1GB /srv/swift-disk
mkfs.xfs /srv/swift-disk
grep -q /srv/swift-disk /etc/fstab || echo '/srv/swift-disk /srv/node/disk xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab
mount -a
chown swift.swift /srv/node/disk

rm -f /etc/swift/account.ring.gz
rm -f /etc/swift/container.ring.gz
rm -f /etc/swift/object.ring.gz
rm -f /etc/swift/account.builder
rm -f /etc/swift/container.builder
rm -f /etc/swift/object.builder

. openrc
. /opt/openstack/bin/activate

swift-ring-builder /etc/swift/object.builder create 10 1 1
swift-ring-builder /etc/swift/container.builder create 10 1 1
swift-ring-builder /etc/swift/account.builder create 10 1 1

swift-ring-builder /etc/swift/object.builder add r1z1-$ip:6000/disk 1
swift-ring-builder /etc/swift/container.builder add r1z1-$ip:6001/disk 1
swift-ring-builder /etc/swift/account.builder add r1z1-$ip:6002/disk 1

swift-ring-builder /etc/swift/object.builder rebalance
swift-ring-builder /etc/swift/container.builder rebalance
swift-ring-builder /etc/swift/account.builder rebalance

chef-client

swift-init all start

#!/bin/bash
# OpenStack을 완전히 삭제하고 재설치하는 스크립트
if ! dpkg -l | grep -q python-keystoneclient; then
	echo 'OpenStack was not installed!'
	exit 1
fi

apt-get purge -y --auto-remove python-keystoneclient && \
rm -rf /usr/lib/python2.7/dist-packages/neutron && \
rm -rf /usr/share/openstack-dashboard && \
chef-client

#!/bin/bash
source /root/openrc
source /opt/openstack/bin/activate
source /etc/bash_completion

NET_NAME=zone100

# create instance
glance_ubuntu=$(glance image-list | awk '/ubuntu-14.04/{print $2}')
nova boot --flavor=2 --availability-zone ${NET_NAME} --image=$glance_ubuntu --key_name=default --poll test${RANDOM}${RANDOM} 

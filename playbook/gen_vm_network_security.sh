#!/bin/bash
source /root/openrc
source /opt/openstack/bin/activate
source /etc/bash_completion


# setting for create network
NET_NAME=zone100
NET_ID=`neutron net-create ${NET_NAME} --provider:network_type vlan --provider:physical_network default --provider:segmentation_id=100 --shared | awk '/ id /{print $4}'`
neutron subnet-create ${NET_NAME} --name ${NET_NAME} --dns-nameserver 10.252.100.1 --allocation-pool start=10.252.100.11,end=10.252.100.250 10.252.100.0/24
for dhcp_agent_id in `neutron agent-list | awk '/DHCP agent/{print $2}'`; do
    neutron dhcp-agent-network-add ${dhcp_agent_id} ${NET_NAME}
done
subnet_id=`neutron subnet-list -- --network_id=${NET_ID} | awk '/start/{print $2}'`
dhcp_ip=`neutron port-list --device-owner=network:dhcp | awk "/${subnet_id}/{print \\$10}" | cut -d '"' -f 2 | head -n 1`
neutron subnet-update ${subnet_id} -- --host-routes type=dict list=true destination=169.254.0.0/16,nexthop=${dhcp_ip}
nova aggregate-create ${NET_NAME} ${NET_NAME}
nova aggregate-add-host ${NET_NAME} compute000
nova aggregate-set-metadata ${NET_NAME} networks=${NET_NAME}


# add security group access rule
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0


# create keypair
nova keypair-add default > ${OS_USERNAME}.pem
chmod 0600 ${OS_USERNAME}.pem
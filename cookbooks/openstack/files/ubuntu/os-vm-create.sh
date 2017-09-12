#!/bin/bash
#
# - setup network
# - setup demo tenant, demo user
#
# GRE Tunneling
# NET_TYPE=tunneling
#
# Provider network with vlan
# NET_TYPE=provider
# VLAN_ID=100
#
set -e

if [ -f `dirname $0`/os-vm-create.rc ]; then
    . `dirname $0`/os-vm-create.rc
fi

# Image for instance
TEMPLATE=${TEMPLATE:-ubuntu-14.04}
FLAVOR=${FLAVOR:-m1.tiny}

NET_TYPE=${NET_TYPE:-provider}
# external subnet
EXTSUBNET=${EXTSUBNET:-10.10.100.0/24}

# tenant private subnet, 혹시 최대한 외부 네트워크와 겹치지 않을 영역으로..
PRISUBNET=${PRISUBNET:-172.16.192/24}

WITH_VOLUME=${WITH_VOLUME:-false}
BOOT_FROM_VOLUME=${BOOT_FROM_VOLUME:-false}
WITH_FLOATING_IP=${WITH_FLOATING_IP:-false}
DNS=${DNS:-8.8.8.8}

if [ -z "$OS_TENANT_NAME" ]; then
    echo "openstack environ variables is not set"
    echo "please run . ~/openrc tenant_name"
    exit
fi

function usage(){
    echo "Usage: `basename $0` vmname"
    echo
    echo "    -c    clear all network items"
    echo "    -t    template"
    echo "    -h    show this screen"
}

function fatal(){
    echo "$@"
    exit 1
}

EXTNET="ext_net"

while getopts "hct:" opt; do
    case $opt in
        h)
            usage
            exit
            ;;

        c)
            # clear all instance and networks
            [[ ! -z `nova list --all-tenants` ]] && \
                nova list --all-tenants | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 nova delete
            [[ ! -z `neutron floatingip-list` ]] && \
                neutron floatingip-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 neutron floatingip-delete
            [[ ! -z `neutron router-list` ]] && \
                neutron router-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 neutron router-gateway-clear
            if [[ ! -z `neutron port-list -- --device_owner network:router_interface` ]]; then
                for port_id in `neutron port-list -- --device_owner network:router_interface | head -n -1 | tail -n +4 | awk '{print $2}'`; do
                    router_id=$(neutron port-show $port_id | grep 'device_id' | awk '{print $4}')
                    subnet_id=$(neutron port-show $port_id | grep 'fixed_ips' | awk '{print $5}' | tr -d ',' | tr -d '"')
                    neutron router-interface-delete $router_id $subnet_id
                done
            fi
            [[ ! -z `neutron subnet-list` ]] && \
                neutron subnet-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 neutron subnet-delete || true
            [[ ! -z `neutron net-list` ]] && \
                neutron net-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 neutron net-delete || true
            [[ ! -z `neutron router-list` ]] && \
                neutron router-list | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 neutron router-delete || true
            exit
            ;;
        t)
            TEMPLATE=$OPTARG
            ;;
        *)
            exit
            ;;
    esac
done

shift $((OPTIND-1))
VM=$1

#
# create external network - only by admin
#
function setup_external_network(){
	if [ "$OS_USERNAME" = 'admin' ]; then
		EXTNET_ID=$(neutron net-list -- --tenant_id=$TENANT_ID --router:external=True | awk "/ $EXTNET / { print \$2 }")
		if [ -z "$EXTNET_ID" ]; then
			# External Netowrk이 vlan인 경우 vlan을 지정한다?
			if [ ! -z "$EXTNET_VLAN" ]; then
				EXTNET_OPT="--provider:network_type vlan --provider:physical_network default --provider:segmentation_id=$EXTNET_VLAN"
			fi

			EXTNET_ID=$(neutron net-create $EXTNET --tenant_id=$TENANT_ID --router:external=True $EXTNET_OPT | grep ' id ' | awk '{print $4}')
		fi

		# create external subnet
		EXTSUBNET_ID=$(neutron net-show $EXTNET_ID | awk "/ subnets / { print \$4 }")
		if [ $EXTSUBNET_ID = "|" ]; then
			if [ ! -z "$EXTSUBNET_IP_POOL" ]; then
				EXTSUBNET_OPT+="--allocation-pool $EXTSUBNET_IP_POOL "
			fi

			EXTSUBNET_ID=$(neutron subnet-create $EXTNET_ID "${EXTSUBNET}" \
						   --tenant_id=$TENANT_ID --name=${EXTNET} \
						   --enable_dhcp=False $EXTSUBNET_OPT | awk '/ id / {print $4}')
		fi
	else
		EXTNET_ID=$(neutron net-list -- --router:external=True | awk "/ $EXTNET / { print \$2 }")
	fi
}

#
# Setup default security group
#
function setup_security_group(){
	if ! nova secgroup-list-rules default | grep -q tcp; then
		echo 'enable ping/ssh'
		nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
		nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
	fi
}

#
# tenant internal network
#

# create private network
function setup_tenant_network(){
    local NET_NAME="${OS_TENANT_NAME}"

	NET_ID=$(neutron net-list --name=${NET_NAME} | awk "/ ${NET_NAME} / { print \$2 }")
	if [ -z "$NET_ID" ]; then
		echo -n 'create tenant private network: '
		NET_ID=$(neutron net-create ${NET_NAME} | grep ' id ' | awk '{print $4}')
		echo "NET=$NET_ID"
	fi

	# create private subnet
	SUBNET_ID=$(neutron net-show $NET_ID | awk "/ subnets / { print \$4 }")
	if [ $SUBNET_ID = "|" ]; then
		echo -n "Create subnet for ${NET_ID}: "
		SUBNET_ID=$(neutron subnet-create $NET_ID "${PRISUBNET}" \
					--name=${NET_NAME} \
					--dns_nameservers list=true ${DNS} | \
					awk '/ id / {print $4}')
		echo "SUBNET=$SUBNET_ID"
	fi
}

function setup_router(){
    # now internal network is working
    # and connect to external network

    # create router for connect to external network
    ROUTER_NAME="${OS_TENANT_NAME}"
    ROUTER_ID=$(neutron router-list -- --tenant_id=$TENANT_ID --name=$ROUTER_NAME | head -n -1 | tail -n +4 | awk '{print $2}')
    if [ -z "$ROUTER_ID" ]; then
        echo -n 'Create router '
        ROUTER_ID=$(neutron router-create --tenant_id=$TENANT_ID $ROUTER_NAME | awk '/ id /{print $4}')
        echo "ROUTER=$ROUTER_ID"
    fi

    # connect router to subnet
    ROUTER_PORT_ID=$(neutron port-list -- --tenant_id=${TENANT_ID} --fixed_ips subnet_id=${SUBNET_ID} --device_owner=network:router_interface | awk '/ip_address/{print $2}')
    if [ -z "$ROUTER_PORT_ID" ]; then
        neutron router-interface-add $ROUTER_ID $SUBNET_ID
        neutron router-gateway-set $ROUTER_ID $EXTNET_ID
    fi
}

function setup_provider_network(){
    VLAN_ID=${VLAN_ID:-100}
    NET_CIDR=${NET_CIDR:-10.252.100.0/24}
    NET_NAME="zone${VLAN_ID}"
    NET_ID=`neutron net-show ${NET_NAME} | awk '/ id /{print $4}'`

    if [ ! -z "$IP_POOL" ]; then
        pool_start=`echo $IP_POOL | cut -d , -f 1`
        pool_end=`echo $IP_POOL | cut -d , -f 2`

        POOL="--allocation-pool start=${pool_start},end=${pool_end}"
    fi

    if [ -z "$NET_ID" ]; then
        NET_ID=`neutron net-create ${NET_NAME} --provider:network_type vlan --provider:physical_network default --provider:segmentation_id=${VLAN_ID} --shared | awk '/ id /{print $4}'`
        neutron subnet-create ${NET_NAME} --name ${NET_NAME} ${POOL} ${NET_CIDR}
    fi

    # setup dhcp agent...
    if ! neutron dhcp-agent-list-hosting-net ${NET_NAME} | grep -q True; then
        for dhcp_agent_id in `neutron agent-list | awk '/DHCP agent/{print $2}'`; do
            neutron dhcp-agent-network-add ${dhcp_agent_id} ${NET_NAME} || true
        done
    fi

    # setup custom routing for metadata
    subnet_id=`neutron subnet-list -- --network_id=${NET_ID} | awk '/start/{print $2}'`
    dhcp_ip=`neutron port-list --device-owner=network:dhcp | awk "/${subnet_id}/{print \\$10}" | cut -d '"' -f 2 | head -n 1`
    neutron subnet-update ${subnet_id} --dns-nameserver 10.20.30.40 -- --host-routes type=dict list=true destination=169.254.0.0/16,nexthop=${dhcp_ip}

    ZONE=${NET_NAME}
    nova aggregate-create ${ZONE} ${ZONE} || true

    for host in `nova host-list | awk '/ compute /{print $2}'`; do
        nova aggregate-add-host ${ZONE} ${host} || true
    done
    nova aggregate-set-metadata ${ZONE} networks=${ZONE} || true
}

function setup_32bit_network(){
    NET_CIDR=${NET_CIDR:-10.252.101.0/24}
    NET_NAME="32net"
    NET_ID=`neutron net-show ${NET_NAME} | awk '/ id /{print $4}'`

    if [ ! -z "$IP_POOL" ]; then
        pool_start=`echo $IP_POOL | cut -d , -f 1`
        pool_end=`echo $IP_POOL | cut -d , -f 2`

        POOL="--allocation-pool start=${pool_start},end=${pool_end}"
    fi

    if [ -z "$NET_ID" ]; then
        NET_ID=`neutron net-create ${NET_NAME} --provider:network_type hostroute --shared | awk '/ id /{print $4}'`
        neutron subnet-create --no-gateway ${NET_NAME} --name ${NET_NAME} ${POOL} ${NET_CIDR}
    fi

    # setup dhcp agent...
    if ! neutron dhcp-agent-list-hosting-net ${NET_NAME} | grep -q True; then
        for dhcp_agent_id in `neutron agent-list | awk '/DHCP agent/{print $2}'`; do
           # 모든 compute host에 neutron-dhcp-agent를 올려야 하며 모두 neutron dhcp-agent-network-add로 등록한다
            neutron dhcp-agent-network-add ${dhcp_agent_id} ${NET_NAME} || true
        done
    fi

    # setup custom routing for metadata
    subnet_id=`neutron subnet-list -- --network_id=${NET_ID} | awk '/start/{print $2}'`
    dhcp_ip=${NET_CIDR%.*}.1
    # 맨처음 dhcp ip를 gateway로 지정한다
    neutron subnet-update ${subnet_id} --dns-nameserver 10.20.30.40 -- --host-routes type=dict list=true destination=169.254.0.0/16,nexthop=${dhcp_ip} destination=0.0.0.0/0,nexthop=${dhcp_ip}
}

function setup_network(){
    case "$NET_TYPE" in
        provider)
            ;;
        tunneling)
            setup_tenant_network
            setup_router
            ;;
        32bit)
            ;;
        *)
            fatal "unknown network type $NET_TYPE"
            ;;
    esac
}


#
# generate keypair
# default keypair name is ${OS_TENANT_NAME}_key
#
function setup_keypair(){
    if ! nova keypair-list | grep " default " > /dev/null ; then
        nova keypair-add default > ${OS_USERNAME}.pem
        chmod 0600 ${OS_USERNAME}.pem
    fi
}

function setup_user(){
    if ! keystone user-get demo > /dev/null ; then
        keystone tenant-create --name demo
        keystone user-create --name demo --pass=demo
        keystone user-role-add --user demo --tenant demo --role Member
    fi

    # 여기서 부터는 user 설정임..
    export OS_USERNAME=demo
    export OS_PASSWORD=demo
    export OS_TENANT_NAME=demo
    export OS_SERVICE_TOKEN
    export OS_SERVICE_ENDPOINT

    setup_security_group
    setup_keypair
}

#
# boot instance
#
function setup_instance(){
    test -z "$VM" && return

    TEMPLATE_ID=$(glance image-list | grep "$TEMPLATE" | head -n 1 | awk '{print $2}')
    echo "TEMPLATE=$TEMPLATE_ID"

    if [ "$BOOT_FROM_VOLUME" = 'true' ]; then
        # @todo flavor에 따라서 디스크 크기 정하기...
        VOLUME=$(cinder create --image-id $TEMPLATE_ID --display-name $VM_root 4 | awk '/ id /{print $4}')
        echo -n "Boot volume=$VOLUME"
        boot_flag="--block_device_mapping vda=$VOLUME:::1"

        # wait for volume create
        while ! cinder list | grep $VOLUME | grep -q "available"; do
            sleep 2
            echo -n '.'
        done

        echo
    else
        boot_flag="--image=$TEMPLATE_ID"
    fi

    VM_ID=$(nova boot --flavor=${FLAVOR} --nic net-id=$NET_ID --key_name=default $boot_flag --poll $VM | awk '/ id /{print $4}')
    echo "VM=$VM_ID"

    # get port id for floating ip
    # wait for port settled
    while [ -z "$PORT_ID" ]; do
        PORT_ID=$(neutron port-list -- --device_id=$VM_ID | awk '/ip_address/{ print $2 }')
        sleep 1
        # @todo 인스턴스 생성 오류가 있을 수 있다.
        status=$(nova show ${VM_ID} | awk '/OS-EXT-STS:vm_state/{ print $4 }')
        if [ "$status" = 'error' ]; then
            fatal "VM creation error, state: $status"
        fi
    done
    echo "PORT=$PORT_ID"

    # create floating ip
    if [ "$WITH_FLOATING_IP" = "true" ]; then
        FLOATINGIP_ID=$(neutron floatingip-create $EXTNET | awk '/ id /{ print $4 }')
        echo "FLOATINGIP_ID=$FLOATINGIP_ID"

        # associate floating ip
        neutron floatingip-associate $FLOATINGIP_ID $PORT_ID
        neutron floatingip-show $FLOATINGIP_ID
    fi

    # create cinder volume and attach
    if [ "$WITH_VOLUME" = "true" ]; then
        VOLUME_ID=$(cinder create --display_name=${VM} 1 | awk '/ id /{print $4}')

        # building 상태에서는 volume을 붙일 수 없어 기다린다.
        while [ $(cinder show ${VOLUME_ID} | awk '/ status /{print $4}') != 'available' ]; do
           sleep 2
        done

        while [ $(nova show ${VM_ID} | awk '/ status /{print $4}') != 'ACTIVE' ]; do
           sleep 2
        done
        nova volume-attach ${VM_ID} ${VOLUME_ID} /dev/vdb
    fi

    nova show $VM_ID
}

function setup_admin_network(){
    case "$NET_TYPE" in
        tunneling)
            setup_external_network
            ;;
        provider)
            setup_provider_network
            ;;
        32bit)
            setup_32bit_network
            ;;
        *)
            fatal "unknown network type $NET_TYPE"
            ;;
    esac
}

# flavor의 Root Disk 크기가 1이면 10으로 늘려준다.
if [ `nova flavor-show ${FLAVOR} | awk '/disk/{print $4}'` = 1 ]; then
    ram=`nova flavor-show ${FLAVOR} | awk '/ ram /{print \$4}'`
    vcpu=`nova flavor-show ${FLAVOR} | awk '/ vcpu /{print \$4}'`

    nova flavor-delete ${FLAVOR}

    FLAVOR_ID=`uuidgen -r`
    nova flavor-create --is-public true ${FLAVOR} `uuidgen -r` ${ram} 10 1
fi

setup_admin_network
setup_user
setup_network
setup_instance

# vim: nu ai aw ts=4 sw=4 et

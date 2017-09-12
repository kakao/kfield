function make_vm {
echo "START"
source /root/openrc

source /opt/openstack/bin/activate
source /etc/bash_completion

export http_proxy=''
export https_proxy=''
export HTTP_PROXY=''
export HTTPS_PROXY=''
export no_proxy=localhost,.stack,127.0.0.1

NET_NAME=zone100
NET_TYPE=$(awk -F' ' '/^tenant_network_types = /{print $3}' /etc/neutron/plugins/ml2/ml2_conf.ini)
echo "1. network base settings...."
if [ "$NET_TYPE" == "hostroute" ];then
    iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
fi
echo "NETTYPE: $NET_TYPE"
echo "2. creating neutron network"
if [ "$NET_TYPE" == "hostroute" ];then
    NET_ID=$(neutron net-create ${NET_NAME} --provider:network_type hostroute --shared | awk '/ id /{print $4}')
else
    NET_ID=$(neutron net-create ${NET_NAME} --provider:network_type vlan --provider:physical_network default --provider:segmentation_id 100 --shared | awk '/ id /{print $4}')
fi
echo "NETWORK: $NET_ID"
echo
echo "3. creating subnet "
if [ "$NET_TYPE" == "hostroute" ];then
    SUBNET_ID=$(neutron subnet-create ${NET_NAME} 10.252.100.0/24 --name ${NET_NAME} --dns-nameserver 10.252.100.1 --no-gateway --allocation-pool start=10.252.100.11,end=10.252.100.250 | awk '/ id /{print $4}')
else
    SUBNET_ID=$(neutron subnet-create ${NET_NAME} 10.252.100.0/24 --name ${NET_NAME} --dns-nameserver 10.252.100.1 --allocation-pool start=10.252.100.11,end=10.252.100.250 | awk '/ id /{print $4}')
fi
echo "SUBNET: $SUBNET_ID"
echo
echo "4. add dhcp agent "
for dhcp_agent_id in $(neutron agent-list | awk '/DHCP agent/{print $2}'); do
    neutron dhcp-agent-network-add "${dhcp_agent_id}" ${NET_NAME}
done
if [ "$NET_TYPE" == "hostroute" ];then
    neutron subnet-update "${SUBNET_ID}" --host-routes type=dict list=true destination=169.254.0.0/16,nexthop=10.252.100.1 destination=0.0.0.0/0,nexthop=10.252.100.1
else
    DHCP_ID=$(neutron port-list --device-owner=network:dhcp | awk "/${SUBNET_ID}/{print \\$10}" | cut -d '"' -f 2 | head -n 1)
    neutron subnet-update "${SUBNET_ID}" --host-routes type=dict list=true destination=169.254.0.0/16,nexthop="${DHCP_ID}"
fi

# l3 agent and firewall test
if [ "$NET_TYPE" == "hostroute" ];then
    ROUTER_NAME=router1
    PUB_NET_NAME=public
    echo "5. creating neutron network - public"
    PUB_NET_ID=$(neutron net-create $PUB_NET_NAME --router:external | awk '/ id /{print $4}')
    echo "PUBLIC NETWORK: $PUB_NET_ID"
    echo
    echo "6. creating neutron network - public"
    PUB_SUBNET_ID=$(neutron subnet-create $PUB_NET_NAME 10.252.120.0/24 --name $PUB_NET_NAME --dns-nameserver 10.252.100.1 --no-gateway --allocation-pool start=10.252.120.11,end=10.252.120.250)
    echo "PUBLIC SUBNET: $PUB_SUBNET_ID"
    echo
    echo "7. creating router"
    neutron router-create $ROUTER_NAME
    ROUTER_PORT_ID=$(neutron port-create "$NET_ID" --fixed-ip SUBNET_ID="$SUBNET_ID",ip_address=10.252.100.11 | awk '/ id /{print $4}')
    echo "ROUTER PORT: $ROUTER_PORT_ID"
    echo
    echo "8. config router"
    neutron router-interface-add $ROUTER_NAME port="$ROUTER_PORT_ID"
    neutron router-gateway-set $ROUTER_NAME "$PUB_NET_ID" --disable-snat
    for l3_agent_id in $(neutron agent-list | awk '/L3 agent/{print $2}'); do
        neutron l3-agent-router-add "$l3_agent_id" $ROUTER_NAME
    done
    echo

    echo "9. creating firewall rule"
    FW_RULE=$(neutron firewall-rule-create --source-ip-address 10.252.100.0/16 --destination-ip-address  10.252.110.0/16 --protocol tcp --destination-port 3306:3307 --action deny | awk '/ id /{print $4}')
    echo "FIREWALL RULE: $FW_RULE"
    echo
    echo "10. creating firewall policy"
    FW_POLICY=$(neutron firewall-policy-create --firewall-rules "$FW_RULE" policy | awk '/ id /{print $4}')
    echo "FIREWALL POLICY: $FW_POLICY"
    echo
    echo "11. creating firewall"
    neutron firewall-create --router $ROUTER_NAME --name firewall "$FW_POLICY"
    echo
fi

echo "a. add availability zone"
COMPUTE=$(nova service-list | grep nova-compute  | grep nova | awk '{ print $6}')
nova aggregate-create ${NET_NAME} ${NET_NAME}
nova aggregate-add-host ${NET_NAME} "${COMPUTE}"
nova aggregate-set-metadata ${NET_NAME} networks=${NET_NAME}

echo "securtiy group "
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova keypair-add default > /tmp/"${OS_USERNAME}".pem
chmod 0600 /tmp/"${OS_USERNAME}".pem

echo "get ubuntu image"
service glance-registry restart
sleep 5
glance_ubuntu=$(glance image-list | grep -v trove-kilo | awk '/ubuntu-14.04/{print $2}')

echo "create vm"
echo "nova boot --flavor=2 --availability-zone=${NET_NAME} --image=${glance_ubuntu} --key_name=default --poll test${RANDOM}${RANDOM}"
#nova boot --flavor 2 --availability-zone ${NET_NAME} --image ${glance_ubuntu} --key_name default --poll test${RANDOM}${RANDOM}

sleep 5
if [ "$NET_TYPE" == "hostroute" ];then
    ip netns exec neutron-global netstat -nlpt|grep bgpd
    if [ $? != 0 ];then
        echo "bgpd process not found.."
        return 1
    fi
    ip netns exec neutron-global ping -c 3 10.252.200.254
    if [ $? != 0 ];then
        echo "can not connect peering network.."
        return 1
    fi
fi
}

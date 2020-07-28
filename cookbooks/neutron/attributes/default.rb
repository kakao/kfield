default[:neutron][:use_syslog] = true

#
# 기본 설정은 ml2, gre tunneling으로 되어있다.
#
# shared vlan networking example
#    :tenant_network_type => 'vlan',
#    :network_vlan_ranges => 'default:100:200',
#    :enable_isolated_metadata => true,
#
# /32환경은 아래 두 개의 attribute가 필요하다
# tenant_network_type가 hostroute로 network 타입을 분리하며
# dhcp_driver neutron.agent.linux.dhcp.DnsmasqQuaggaAddon 에서는 dnsmasq를 상속받아 quagga  daemon을 통해 /32를 위한 route를 구현 한다
#
# /32 networking example
#    :tenant_network_type => 'hostroute',
#    :dhcp_driver=> 'neutron.agent.linux.dhcp_quagga.DnsmasqQuaggaAddon',
#    :enable_isolated_metadata => true,
#
default[:neutron][:plugin] = 'ml2'
default[:neutron][:tenant_network_type] = 'gre'
default[:neutron][:tunnel_id_ranges] = '1:1000'
default[:neutron][:use_veth_interconnection] = true
default[:neutron][:allow_overlapping_ips] = true

default[:neutron][:integration_bridge] = 'br-int'
default[:neutron][:guest_iface] = 'eth1'
default[:neutron][:guest_bridge] = "br-#{node[:neutron][:guest_iface]}"
default[:neutron][:flat_networks] = ''

# port에 할당 가능한 fixed_ip가 기본값이 5개인데, virtual machine만 서비스 하면
# 문제 없지만 container를 서비스하는 경우라면 5개로는 부족하다.
# 우선 1024개 정도로 늘려놓음
default[:neutron][:max_fixed_ips_per_port] = 1024

default[:neutron][:plugin_agent] = 'linuxbridge'
case node[:neutron][:plugin_agent]
when 'openvswitch'
    default[:neutron][:plugin_file] = '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini'
    default[:neutron][:plugin_file_template] = 'ovs_neutron_plugin.ini.erb'
when 'linuxbridge'
    default[:neutron][:plugin_file] = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'
    default[:neutron][:plugin_file_template] = 'linuxbridge_conf.ini.erb'
else
    fail "neutron plugin agent #{node[:neutron][:plugin_agent]} not supported!"
end

# tunneling을 사용할 경우는 l3 통신이기 때문에 bridge_mapping이 필요 없다.
if node[:neutron][:tenant_network_type] == 'vxlan'
    default[:neutron][:enable_vxlan] = true
else
    default[:neutron][:enable_vxlan] = false
end

case node[:neutron][:tenant_network_type]
when 'vlan'
    case node[:neutron][:plugin_agent]
    when 'openvswitch'
        default[:neutron][:bridge_mappings] = "default:#{node[:neutron][:guest_bridge]}"
    when 'linuxbridge'
        default[:neutron][:bridge_mappings] = "default:#{node[:neutron][:guest_iface]}"
    else
        fail "neutron plugin agent #{node[:neutron][:plugin_agent]} not supported!"
    end
when 'gre'
    default[:neutron][:bridge_mappings] = nil
when 'flat'
    case node[:neutron][:plugin_agent]
    when 'openvswitch'
        default[:neutron][:bridge_mappings] = "default:#{node[:neutron][:guest_bridge]}"
    when 'linuxbridge'
        default[:neutron][:bridge_mappings] = "default:#{node[:neutron][:guest_iface]}"
    else
        fail "neutron plugin agent #{node[:neutron][:plugin_agent]} not supported!"
    end
    default[:neutron][:flat_networks] = '*'
when 'hostroute'
    default[:neutron][:bridge_mappings] = nil
end

# vlan options
default[:neutron][:network_vlan_ranges] = 'default:1000:2999'

# gre options
default[:neutron][:local_ip] = nil

# true면 security group driver를 NoopFirewallDriver로 설정
# 원칙적으로는 security group extension을 disable하면 좋겠지만,
# nova, neutron 코드에서 security group이 enable되어 있다고 가정하는 코드가 너무 많다.
default[:neutron][:enable_security_group] = false
if node[:neutron][:enable_security_group]
    case node[:neutron][:plugin_agent]
    when 'openvswitch'
        default[:neutron][:firewall_driver] = 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'
    when 'linuxbridge'
        default[:neutron][:firewall_driver] = 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver'
    else
        fail "neutron plugin agent #{node[:neutron][:plugin_agent]} not supported!"
    end
else
    default[:neutron][:firewall_driver] = 'neutron.agent.firewall.NoopFirewallDriver'
end

# 포트 기본 값이 hybrid_plug를 사용하는 것인데, 이를 사용하는 이유는 security group이 구현되는
# iptables가 ovs에 적용되지 않아서 linux bridge를 중간에 끼어넣어 iptables를 적용하기 위함이다.
# 하지만 security group을 사용하지 않는 경우에는 굳지 linux bridge를 중간에 끼워 넣을 이유가 없어서
# hybrid plug를 사용하지 않는 옵션을 만들었음.
#
# enable_security_group = false일 경우 이 옵션도 false로 만들면 될 것 같지만,
# enable_security_group = flase가 security group extension을 load하지 않는 기능까지 사용하게 되면
# 무슨 영향이 있을지 몰라서 우선은 분리함.
#
# 이 옵션은 ovs인 경우만 적용됨
# enable_security_group = false일 경우는 use_ovs_hybrid_plug = false인 것이 좋다.
default[:neutron][:use_ovs_hybrid_plug] = true

default[:neutron][:quota][:network] = 10
default[:neutron][:quota][:subnet] = 10
# neutron의 포트 quota로 nova quota가 영향을 받을 수 있어서 무제한으로 풀어놓음
default[:neutron][:quota][:port] = -1
default[:neutron][:quota][:security_group] = 10
default[:neutron][:quota][:security_group_rule] = 100
default[:neutron][:quota][:vip] = 10
default[:neutron][:quota][:pool] = 10
default[:neutron][:quota][:member] = -1
default[:neutron][:quota][:router] = 10
default[:neutron][:quota][:floatingip] = 50

default[:neutron][:api_workers] = 8
default[:neutron][:rpc_workers] = 8
default[:neutron][:metadata_workers] = 2
default[:neutron][:metadata_backlog] = 128

default[:neutron][:dsr_mode] = ''   # l3dsr_global or l3dsr_vip or ''
default[:neutron][:minimize_polling] = true

# l3 Service
default[:neutron][:l3_service_plugin] = 'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'
default[:neutron][:l3_nat_agent] = 'neutron.agent.l3_agent_hostroute.L3NATAgentWithStateReport'
default[:neutron][:fwaas][:enable] = false
default[:neutron][:fwaas][:firewall_driver] = "neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver"
default[:neutron][:neutron_service_plugins] = []

# @todo openvswitch plugin은 나중에 삭제하자...
case node[:neutron][:plugin]
when 'openvswitch'
    default[:neutron][:plugin_config] = '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini'
    default[:neutron][:core_plugin] = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
    default[:neutron][:service_plugins] = %w{}

when 'ml2'
    default[:neutron][:plugin_config] = '/etc/neutron/plugins/ml2/ml2_conf.ini'
    default[:neutron][:core_plugin] = 'neutron.plugins.ml2.plugin.Ml2Plugin'
    default[:neutron][:service_plugins] = [node[:neutron][:l3_service_plugin]] | node[:neutron][:neutron_service_plugins]

    default[:neutron][:mechanism_drivers] = node[:neutron][:plugin_agent]
else
    fail "neutron plugin #{node[:neutron][:plugin]} not supported!"
end

#
# dhcp_agent
#
case node[:neutron][:plugin_agent]
when 'openvswitch'
    default[:neutron][:interface_driver] = 'neutron.agent.linux.interface.OVSInterfaceDriver'
when 'linuxbridge'
    default[:neutron][:interface_driver] = 'neutron.agent.linux.interface.BridgeInterfaceDriver'
else
    fail "neutron plugin agent #{node[:neutron][:plugin_agent]} not supported!"
end
default[:neutron][:use_namespaces] = true
default[:neutron][:ovs_use_veth] = true
# /32 구현을 dhcp에서 많은 부분을 구현 하므로 dhcp_driver 분류 attribute 추가
# /32 의 경우 neutron.agent.linux.dhcp.DnsmasqQuaggaAddon
default[:neutron][:dhcp_driver] = 'neutron.agent.linux.dhcp.Dnsmasq'

# dhcp agent에서 metadata proxy를 띄울지 설정
# L3 agent를 사용한다면, 거기서 NAT을 이용해서 처리하기 때문에 필요없다.
default[:neutron][:enable_isolated_metadata] = true
default[:neutron][:enable_metadata_network] = false
# metadata에 보이는 hostname, public-hostname의 설정에 사용됨
default[:neutron][:dhcp_domain] = 'internal'
default[:neutron][:dnsmasq_dns_servers] = nil

# metadata agent
default[:neutron][:service_metadata_proxy] = true
default[:neutron][:metadata_proxy_shared_secret] = 'secret'

#
# LBaaS settings
#
default[:neutron][:lbaas][:enable] = false
default[:neutron][:lbaas][:driver] = 'haproxy'
default[:neutron][:lbaas][:adx_devices] = []
default[:neutron][:lbaas][:adx_password] = ''

case node[:neutron][:lbaas][:driver]
when 'haproxy'
    default[:neutron][:lbaas][:plugin_driver] = 'Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver'
    default[:neutron][:lbaas][:driver_class] = 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver'
when 'adx'
    default[:neutron][:lbaas][:plugin_driver] = 'ADX:kakao.openstack.neutron.lbaas.adx_driver.PluginDriver'
    default[:neutron][:lbaas][:driver_class] = 'kakao.openstack.neutron.lbaas.adx_driver.ADXDriver'
end

default[:neutron][:network_auto_schedule] = false
default[:neutron][:router_auto_schedule] = false

default[:neutron][:dhcp_relay_ips] = ''

#
# Route peering Interface & BGP Attribute
#
default[:neutron][:host_route][:enable_route] = false
default[:neutron][:host_route][:route_phy_interface] = 'eth1'
default[:neutron][:host_route][:route_ip_cidr] = '10.252.200.200/24'
default[:neutron][:host_route][:neighbor] = '10.252.200.254'
default[:neutron][:host_route][:static_routes] = '0.0.0.0/0:10.252.200.254'
default[:neutron][:host_route][:ibgp_as] = 10101
default[:neutron][:host_route][:router_pass] = 'pass'
default[:neutron][:host_route][:router_enable_pass] = 'pass'
# hostroute에서 rtproto option을 이용해 neturon 다른 부분과 route 충돌을 없앰
default[:neutron][:host_route][:rtproto] = 'static'

default[:neutron][:host_route][:route_daemon] = 'quagga'
default[:neutron][:host_route][:global_namespace] = 'neutron-global'
default[:neutron][:host_route][:namespace_bridge] = 'br-global'
default[:neutron][:host_route][:storage_routes] = nil
default[:neutron][:host_route][:storage_root_interface] = 'root-st'
default[:neutron][:host_route][:storage_ns_interface] = 'ns-st'
default[:neutron][:host_route][:storage_ip_cidr] = nil

default[:neutron][:policy][:create_router_admin_only] = true
default[:neutron][:policy][:create_network_admin_only] = true
default[:neutron][:policy][:ecmp_floating_ip_admin] = false

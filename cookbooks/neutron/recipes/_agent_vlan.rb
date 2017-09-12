if check_environment_jenkins
  template '/tmp/interfaces' do
    source 'interfaces.erb'
    user 'root'
    group 'root'
    mode '0644'
    variables({
      :address => node['ipaddress'],
      :default_gateway => node['network']['default_gateway']
    })
  end

  if node[:neutron][:plugin_agent] == 'openvswitch'
    execute "prepare-single-network" do
      command <<-EOF
         ovs-vsctl add-br br0
         /etc/init.d/networking stop
         ovs-vsctl add-port br0 #{node[:neutron][:guest_iface]}
         cp /tmp/interfaces /etc/network/

         /sbin/ifconfig #{node[:neutron][:guest_iface]} 0.0.0.0 up

         ovs-vsctl add-br br-eth0
         ip link add br0-veth type veth peer name br-eth0-veth
         ovs-vsctl add-port br0 br0-veth
         ovs-vsctl add-port br-eth0 br-eth0-veth
         ovs-vsctl add-br br-int
         /etc/init.d/networking start
         /sbin/ifup br0
      EOF
      not_if "ovs-vsctl br-exists br0"
    end
  else
    execute "prepare-single-network" do
      command <<-EOF
         brctl addbr br0
         /etc/init.d/networking stop
         ip link add #{node[:neutron][:guest_iface]} type dummy
         brctl addif br0 eth0
         brctl addif br0 #{node[:neutron][:guest_iface]}
         cp /tmp/interfaces /etc/network/interfaces
         /sbin/ifconfig eth0 0.0.0.0 up
         /sbin/ifconfig #{node[:neutron][:guest_iface]} 0.0.0.0 up
         /etc/init.d/networking start
         /sbin/ifup br0
      EOF
      not_if "brctl show br0 | grep 'No such device"
    end
  end
else
  if node[:neutron][:plugin_agent] == 'openvswitch'
    # setup geust network bridge`
    execute 'add vlan bridge' do
        command "ovs-vsctl add-br #{node[:neutron][:guest_bridge]}"
        not_if "ovs-vsctl br-exists #{node[:neutron][:guest_bridge]}"
    end

    execute "add #{node[:neutron][:guest_iface]} to #{node[:neutron][:guest_bridge]}" do
        command "ovs-vsctl add-port #{node[:neutron][:guest_bridge]} #{node[:neutron][:guest_iface]}"
        not_if "ovs-vsctl list-ports #{node[:neutron][:guest_bridge]} | grep '^#{node[:neutron][:guest_iface]}$'"
    end
  end

  # guest interface에 address 제거
  execute "remove ip address #{node[:neutron][:guest_iface]}" do
      command "/sbin/ifconfig #{node[:neutron][:guest_iface]} 0.0.0.0 up"
  end
end
# 아래처럼 ifconfig resource를 사용하려고 했지만.. 안되네... ㅠㅠ
# node["network"]["interfaces"][node[:neutron][:guest_iface]]["addresses"].select { |address, data| data["family"] == "inet" }.each do | addr, v |
#     fail "#{addr}, #{v}, #{node[:neutron][:guest_iface]}"
#     ifconfig addr do
#         device node[:neutron][:guest_iface]
#         mask v[:netmask]
#         action :delete
#     end
# end

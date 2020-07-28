# @fixme tunneling에 사용될 ip address는 node[:neutron][:guest_iface]에 설정되어 있다고 가정한다.
unless node[:network][:interfaces][node[:neutron][:guest_iface]].nil?
    addrs = node["network"]["interfaces"][node[:neutron][:guest_iface]]["addresses"].select { |address, data| data["family"] == "inet" }
    ipaddr = addrs.keys[0]

    fail "tunnel interface #{node[:neutron][:guest_iface]} is not up!" unless ipaddr
    node.set[:local_ip] = ipaddr
else
    node.set[:local_ip] = nil
end

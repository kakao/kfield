package 'quagga'
if check_environment_jenkins
  execute "prepare-single-network" do
    command <<-EOF
       ip link add #{node[:neutron][:host_route][:route_phy_interface]} type veth peer name pe-#{node[:neutron][:host_route][:route_phy_interface]}
       /sbin/ifconfig pe-#{node[:neutron][:host_route][:route_phy_interface]} #{node[:neutron][:host_route][:neighbor]} netmask 255.255.255.0 up
    EOF
    not_if "ifconfig pe-#{node[:neutron][:host_route][:route_phy_interface]}"
  end
  template "/etc/quagga/zebra.conf" do
    source "sandbox-zebra.conf.erb"
  end

  template "/etc/quagga/debian.conf" do
    source "sandbox-debian.conf.erb"
  end

  template "/etc/quagga/daemons" do
    source "sandbox-daemons.erb"
  end

  template "/etc/quagga/bgpd.conf" do
    source "sandbox-bgpd.conf.erb"
  end
end

service 'quagga' do
    provider Chef::Provider::Service::Debian
    supports :status => :true, :restart => :true, :reload => :true
    action [:enable, :start]
    subscribes :restart, "template[/etc/quagga/bgpd.conf]"
end
include_recipe "#{cookbook_name}::hostroute"

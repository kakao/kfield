# peering network upstart
template "/etc/init/hostroute-peering-network.conf" do
  source "init-hostroute-peering-network.conf.erb"
end

link "/etc/init.d/hostroute-peering-network" do
  to '/lib/init/upstart-job'
end

service "hostroute-peering-network" do
  provider Chef::Provider::Service::Upstart
  supports status: true, restart: true, reload: true
  action [:enable, :start]
end

if node[:neutron][:host_route][:route_daemon] == 'quagga'
  package 'quagga'

  # zebra/bgpd config, upstart
  template "/etc/quagga/hostroute-zebra.conf" do
    source "hostroute-zebra.conf.erb"
  end

  template "/etc/init/hostroute-quagga-zebra.conf" do
    source "init-hostroute-quagga-zebra.conf.erb"
  end

  link "/etc/init.d/hostroute-quagga-zebra" do
    to '/lib/init/upstart-job'
  end

  service "hostroute-quagga-zebra" do
    provider Chef::Provider::Service::Upstart
    supports status: true, restart: true, reload: true
    action [:enable, :start]
  end

  template "/etc/quagga/hostroute-bgpd.conf" do
    source "hostroute-bgpd.conf.erb"
  end

  template "/etc/init/hostroute-quagga-bgpd.conf" do
    source "init-hostroute-quagga-bgpd.conf.erb"
  end

  link "/etc/init.d/hostroute-quagga-bgpd" do
    to '/lib/init/upstart-job'
  end

  service "hostroute-quagga-bgpd" do
    provider Chef::Provider::Service::Upstart
    supports status: true, restart: true, reload: true
    action [:enable, :start]
  end
end

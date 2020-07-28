include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-dhcp-agent"

template '/etc/neutron/dhcp_agent.ini' do
  source 'dhcp_agent.ini.erb'
  mode '0644'
  variables({
  })
  notifies :restart, 'service[neutron-dhcp-agent]'
end

template '/etc/neutron/route.ini' do
  source 'route.ini.erb'
  mode '0644'
  variables({
  })
  notifies :restart, 'service[neutron-dhcp-agent]'
end

service 'neutron-dhcp-agent' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/neutron/neutron.conf]"
end

logrotate_app 'neutron-dhcp-agent' do
  cookbook 'logrotate'
  path '/var/log/neutron/dhcp-agent.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 neutron neutron'
  postrotate 'restart neutron-dhcp-agent >/dev/null 2>&1 || true'
end

return unless node[:neutron][:lbaas][:enable] == true

include_recipe "#{cookbook_name}::common"

template '/etc/neutron/lbaas_agent.ini' do
  source 'lbaas_agent.ini.erb'
  notifies :restart, 'service[neutron-lbaas-agent]'
end

service 'neutron-lbaas-agent' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]'
  subscribes :restart, 'bash[install python-kakao-openstack]'
end

logrotate_app 'neutron-lbaas-agent' do
  cookbook 'logrotate'
  path '/var/log/neutron/lbaas-agent.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 neutron neutron'
  postrotate 'restart neutron-lbaas-agent >/dev/null 2>&1 || true'
end

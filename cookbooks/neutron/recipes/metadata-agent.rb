include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-metadata-agent"

api_host = get_api_host
auth_addr = get_auth_address

template '/etc/neutron/metadata_agent.ini' do
  source 'metadata_agent.ini.erb'
  mode '0644'
  variables({
    :api_host => api_host,
    :auth_addr => auth_addr,
  })
  notifies :restart, 'service[neutron-metadata-agent]'
end

service 'neutron-metadata-agent' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]'
end

# logrotate
logrotate_app 'neutron-metadata-agent' do
  cookbook 'logrotate'
  path '/var/log/neutron/metadata-agent.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 neutron neutron'
  postrotate 'restart neutron-metadata-agent >/dev/null 2>&1 || true'
end

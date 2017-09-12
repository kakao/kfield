return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-engine"

execute 'heat sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/heat-manage db_sync"
  user 'heat'
  group 'heat'
end

service 'heat-engine' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/heat/heat.conf]'
end

logrotate_app 'heat-engine' do
  cookbook 'logrotate'
  path '/var/log/heat/heat-engine.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 heat heat'
  postrotate 'restart heat-engine >/dev/null 2>&1 || true'
end

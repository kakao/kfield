return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api-cloudwatch"

service 'heat-api-cloudwatch' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/heat/heat.conf]'
end

logrotate_app 'heat-cloudwatch' do
  cookbook 'logrotate'
  path '/var/log/heat/heat-cloudwatch.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 heat heat'
  postrotate 'restart heat-cloudwatch >/dev/null 2>&1 || true'
end

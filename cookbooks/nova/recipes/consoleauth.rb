include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-consoleauth"

service 'nova-consoleauth' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

logrotate_app 'nova-consoleauth' do
  cookbook 'logrotate'
  path '/var/log/nova/nova-consoleauth.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 nova nova'
  postrotate 'restart nova-consoleauth >/dev/null 2>&1 || true'
end

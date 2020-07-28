include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-conductor"

service 'nova-conductor' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

logrotate_app 'nova-conductor' do
  cookbook 'logrotate'
  path '/var/log/nova/nova-conductor.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 nova nova'
  postrotate 'restart nova-conductor >/dev/null 2>&1 || true'
end

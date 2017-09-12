include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-scheduler"

service 'nova-scheduler' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/nova/nova.conf]"
  subscribes :restart, "bash[install python-kakao-openstack]"
end

logrotate_app 'nova-scheduler' do
  cookbook 'logrotate'
  path '/var/log/nova/nova-scheduler.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 nova nova'
  postrotate 'restart nova-scheduler >/dev/null 2>&1 || true'
end

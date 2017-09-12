return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-scheduler"

service 'cinder-scheduler' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/cinder/cinder.conf]"
end

# logrotate
logrotate_app 'cinder-scheduler' do
  cookbook 'logrotate'
  path '/var/log/cinder/cinder-scheduler.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 cinder cinder'
  postrotate 'restart cinder-scheduler >/dev/null 2>&1 || true'
end

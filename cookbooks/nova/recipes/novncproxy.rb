return unless node[:nova][:dashboard_console] == 'novnc'

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-novncproxy"

service 'nova-novncproxy' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

# logrotate
logrotate_app 'nova-novncproxy' do
  cookbook 'logrotate'
  path '/var/log/nova/nova-novncproxy.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 nova nova'
  postrotate 'restart nova-novncproxy >/dev/null 2>&1 || true'
end

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-volume"
include_recipe "#{cookbook_name}::_backend_#{node[:cinder][:backend]}"

template '/etc/init/cinder-volume.conf' do
  source 'cinder-volume.conf.erb'
  mode 0644
  notifies :restart, 'service[cinder-volume]'
end

service 'cinder-volume' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/cinder/cinder.conf]"
end

execute 'cinder sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/cinder-manage db sync"
end

logrotate_app 'cinder-volume' do
  cookbook 'logrotate'
  path '/var/log/cinder/cinder-volume.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 cinder cinder'
  postrotate 'restart cinder-volume >/dev/null 2>&1 || true'
end

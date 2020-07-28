::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-registry"

rabbit_node = nodes_by_role "openstack-rabbitmq", {:wait=>true}
mysql_host = get_database_host
memcached_node = nodes_by_role "memcached", {:wait=>true}

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?
fail 'memcached node not found' unless memcached_node

glance_password = dbpassword_for 'glance'
auth_addr = get_auth_address

sql_connection = "mysql://glance:#{glance_password}@#{mysql_host}/glance"
api_addr = get_api_address

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  mode '0644'
  user 'glance'
  group 'glance'
  variables({
    :sql_connection => sql_connection,
    :rabbit_node => rabbit_node,
    :api_addr => api_addr,
    :auth_addr => auth_addr,
    :cookbook_name => cookbook_name,
    :memcached_node => memcached_node,
  })
  notifies :restart, "service[glance-registry]", :immediately
end

service 'glance-registry' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
end

execute 'glance sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/glance-manage db_sync"
end

#include_recipe "#{cookbook_name}::_upload_cloud_images"

glance_upload_cloud_images 'images' do
  auth_addr auth_addr
end

logrotate_app 'glance-registry' do
  cookbook 'logrotate'
  path '/var/log/glance/registry.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 glance glance'
  postrotate 'restart glance-registry >/dev/null 2>&1 || true'
end

::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

rabbit_node = nodes_by_role "openstack-rabbitmq", {:wait=>true}
mysql_host = get_database_host
memcached_node = nodes_by_role "memcached", {:wait=>true}

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?
fail 'memcached node not found' unless memcached_node

cinder_password = dbpassword_for 'cinder'
sql_connection = "mysql://cinder:#{cinder_password}@#{mysql_host}/cinder"

api_host = get_api_host
auth_addr = get_auth_address
api_addr = get_api_address

template '/etc/cinder/cinder.conf' do
  source 'cinder.conf.erb'
  user 'cinder'
  group 'cinder'
  mode '0644'
  variables({
    :sql_connection => sql_connection,
    :rabbit_node => rabbit_node,
    :api_host => api_host,
    :auth_addr => auth_addr,
    :api_addr => api_addr,
    :cookbook_name => cookbook_name,
    :memcached_node => memcached_node,
  })
end

execute 'cinder db sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/cinder-manage db sync"
end

directory '/var/log/cinder' do
  group 'adm'
  owner 'cinder'
  recursive true
  mode '0755'
end

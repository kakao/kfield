return unless node[:openstack][:enabled_service].include?(cookbook_name)

::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

rabbit_node = nodes_by_role 'openstack-rabbitmq', {:wait=>true}
mysql_host = get_database_host
memcached_node = nodes_by_role "memcached", {:wait=>true}

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?
fail 'memcached node not found' unless memcached_node

heat_password = dbpassword_for 'heat'
sql_connection = "mysql://heat:#{heat_password}@#{mysql_host}/heat"

auth_addr = get_auth_address
api_addr = get_api_address

template '/etc/heat/heat.conf' do
  source 'heat.conf.erb'
  user 'heat'
  group 'heat'
  variables({
    :sql_connection => sql_connection,
    :rabbit_node => rabbit_node,
    :auth_addr => auth_addr,
    :api_addr => api_addr,
    :cookbook_name => cookbook_name,
    :memcached_node => memcached_node,
  })
end

keystone_role 'heat_stack_user' do
  auth_addr auth_addr
end

directory '/var/log/heat' do
  group 'adm'
  owner 'heat'
  recursive true
  mode '0755'
end

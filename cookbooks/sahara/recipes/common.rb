sahara_enabled = node[:openstack][:enabled_service].include?('sahara')
return unless sahara_enabled

::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

rabbit_node = nodes_by_role 'openstack-rabbitmq'
mysql_host = get_database_host

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?

sahara_password = dbpassword_for 'sahara'
sql_connection = "mysql://sahara:#{sahara_password}@#{mysql_host}/sahara"

auth_addr = get_auth_address
api_addr = get_api_address

template '/etc/sahara/sahara.conf' do
  source 'sahara.conf.erb'
  user 'sahara'
  group 'sahara'
  variables({
    :sql_connection => sql_connection,
    :rabbit_node => rabbit_node,
    :auth_addr => auth_addr,
    :api_addr => api_addr,
    :cookbook_name => cookbook_name,
    :plugins => node[:sahara][:plugins].join(","),
  })
end

directory '/var/log/sahara' do
  group 'adm'
  owner 'sahara'
  recursive true
  mode '0755'
end

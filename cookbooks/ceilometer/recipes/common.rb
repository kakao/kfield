return unless node[:openstack][:enabled_service].include?(cookbook_name)

::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

return unless node[:openstack][:enabled_service].include?('ceilometer')

datastore_node = node_by_role 'ceilometer-datastore'
rabbit_node = nodes_by_role "openstack-rabbitmq"
memcached_node = nodes_by_role "memcached", {:wait=>true}

fail 'datastore node not found' unless datastore_node
fail 'rabbitmq node not found' if rabbit_node.empty?
fail 'memcached node not found' unless memcached_node

ceilometer_password = dbpassword_for 'ceilometer'

auth_addr = get_auth_address
api_addr = get_api_address

connection = "mongodb://ceilometer:#{ceilometer_password}@#{datastore_node[:fqdn]}/ceilometer"

template '/etc/ceilometer/ceilometer.conf' do
  source 'ceilometer.conf.erb'
  owner 'ceilometer'
  group 'ceilometer'
  mode 00644
  variables({
    :connection => connection,
    :rabbit_node => rabbit_node,
    :api_addr => api_addr,
    :auth_addr => auth_addr,
    :cookbook_name => cookbook_name,
    :memcached_node => memcached_node,
  })
end

template '/etc/ceilometer/pipeline.yaml' do
  source 'pipeline.yaml.erb'
  owner 'ceilometer'
  group 'ceilometer'
  mode 00644
  variables({
  })
end

directory '/var/log/ceilometer' do
  group 'adm'
  owner 'ceilometer'
  recursive true
  mode '0755'
end

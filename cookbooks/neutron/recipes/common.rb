::Chef::Resource::User.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

rabbit_node = nodes_by_role "openstack-rabbitmq", {:wait=>true}
mysql_host = get_database_host

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?

_service_plugins = []
_service_plugins += node[:neutron][:service_plugins]
_service_plugins << 'neutron.services.loadbalancer.plugin.LoadBalancerPlugin' if node[:neutron][:lbaas][:enable]

service_providers = []
service_providers << "LOADBALANCER:#{node[:neutron][:lbaas][:plugin_driver]}" if node[:neutron][:lbaas][:enable]

neutron_password = dbpassword_for 'neutron'
sql_connection = "mysql://neutron:#{neutron_password}@#{mysql_host}/neutron"

auth_addr = get_auth_address
api_addr = get_api_address

template '/etc/neutron/neutron.conf' do
  source 'neutron.conf.erb'
  user 'root'
  group 'neutron'
  mode '0644'
  variables({
    :rabbit_node => rabbit_node,
    :service_plugins => _service_plugins.join(','),
    :service_providers => service_providers.join(','),
    :sql_connection => sql_connection,
    :auth_addr => auth_addr,
    :api_addr => api_addr,
    :cookbook_name => cookbook_name,
  })
end

include_recipe "#{cookbook_name}::install-plugin"

template node[:neutron][:plugin_file] do
  source node[:neutron][:plugin_file_template]
  variables({
    :sql_connection => sql_connection,
    :auth_addr => auth_addr,
  })
end

template "/etc/neutron/plugins/ml2/ml2_conf.ini" do
  source "ml2_conf.ini.erb"
  only_if { node[:neutron][:plugin] == 'ml2'}
end

# mechanism driver configuration용 link, 다른 mechanism driver를 사용한다면 해당 설정으로 변경한다.
link '/etc/neutron/plugins/plugin.ini' do
  action node[:neutron][:plugin] == 'ml2' ? :create : :delete
  to node[:neutron][:plugin_file]
end

cookbook_file '/etc/bash_completion.d/neutron' do
  source 'bash-completion'
end

template "/etc/neutron/policy.json" do
  source "policy.json.erb"
  user 'root'
  group 'neutron'
  mode '0644'
end

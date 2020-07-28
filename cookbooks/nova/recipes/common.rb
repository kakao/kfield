::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe 'glance::client'
include_recipe 'cinder::client' if node[:openstack][:enabled_service].include?('cinder')
include_recipe 'openstack::ceph-client' if [node[:glance][:backend], node[:cinder][:backend]].include?('ceph')

include_recipe "#{cookbook_name}::install"

rabbit_node = nodes_by_role "openstack-rabbitmq", {:wait=>true}
memcached_node = nodes_by_role "memcached", {:wait=>true}

mysql_host = get_database_host

fail 'rabbitmq node not found' if rabbit_node.empty?
fail 'memcached node not found' unless memcached_node

nova_password = dbpassword_for 'nova'
sql_connection = node.roles.include?('nova-conductor') ? "mysql://nova:#{nova_password}@#{mysql_host}/nova" : 'N/A'

api_host = get_api_host
api_addr = get_api_address
auth_addr = get_auth_address

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  user 'nova'
  group 'nova'
  mode '0640'
  variables({
    :sql_connection => sql_connection,
    :rabbit_node => rabbit_node,
    :memcached_node => memcached_node,
    :auth_addr => auth_addr,
    :api_host => api_host,
    :api_addr => api_addr,
    :cookbook_name => cookbook_name,
  })
end

template "/etc/nova/vendor.json" do
  source 'vendor.json.erb'
    user 'nova'
    group 'nova'
    mode '0640'
  only_if { node[:nova][:vendordata_jsonfile_path] }
end

# nova auto completion
cookbook_file '/etc/bash_completion.d/nova' do
  source 'bash_completion.rc'
  mode 00644
end

cookbook_file '/etc/bash_completion.d/nova-manage' do
  source 'nova-manage.bash_completion'
  mode 00644
end

directory '/var/log/nova' do
  group 'adm'
  owner 'nova'
  recursive true
  mode '0755'
end

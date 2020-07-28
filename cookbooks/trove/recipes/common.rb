::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

api_addr = get_api_address
auth_addr = get_auth_address

rabbit_node = nodes_by_role 'openstack-rabbitmq'
mysql_host = get_database_host
trove_password = dbpassword_for 'trove'
sql_connection = "mysql://trove:#{trove_password}@#{mysql_host}/trove"

instance_name_check_regex = '^([a-zA-Z0-9][-]*){0,62}([a-zA-Z0-9])$'

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?

keystone_service 'trove' do
  type 'database'
  description 'OpenStack Database as a Service'
  auth_addr auth_addr
end

keystone_endpoint 'trove' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8779/v1.0/%(tenant_id)s"
  admin_url    "#{ api_addr }:8779/v1.0/%(tenant_id)s"
  internal_url "#{ api_addr }:8779/v1.0/%(tenant_id)s"
  auth_addr auth_addr
end

binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

%w{ trove.conf trove-conductor.conf trove-taskmanager.conf trove-guestagent.conf}.each do |f|
  template "/etc/trove/#{f}" do
    source "#{f}.erb"
    user 'trove'
    group 'trove'
    mode '0644'
    variables({
      :verbose => node[:openstack][:verbose],
      :debug => node[:openstack][:debug][:trove],
      :rabbit_node => rabbit_node,
      :sql_connection => sql_connection,
      :api_addr => api_addr,
      :auth_addr => auth_addr,
      :network_label => node[:trove][:network_label],
      :instance_name_check_regex => instance_name_check_regex,
    })
  end
end

execute 'trove db sync' do
  command "#{binprefix}trove-manage --config-file=/etc/trove/trove.conf db_sync"
  user 'trove'
  group 'trove'
end

node[:trove][:enabled_databases].each do |db, dbinfo|
  execute "update trove datastore infomation #{db}" do
    command "#{binprefix}trove-manage --config-file=/etc/trove/trove.conf datastore_update #{db} \"\" "
    user 'trove'
    group 'trove'
  end
end

cookbook_file '/etc/bash_completion.d/trove' do
  source 'bash_completion'
end

trove_enabled = node[:openstack][:enabled_service].include?('trove')
return unless trove_enabled

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-taskmanager"

api_addr = get_api_address
auth_addr = get_auth_address

rabbit_node = nodes_by_role 'openstack-rabbitmq'
mysql_host = get_database_host
trove_password = dbpassword_for 'trove'
sql_connection = "mysql://trove:#{trove_password}@#{mysql_host}/trove"

log "sql_connection : #{sql_connection}"

node[:trove][:enabled_databases].each do |db, dbinfo|
  template "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}/trove/templates/#{db}/config.template" do
    source "#{db}.config.template"
  end
end

service 'trove-taskmanager' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/trove/trove-taskmanager.conf]'
end

logrotate_app 'trove-taskmanager' do
  cookbook 'logrotate'
  path '/var/log/trove/trove-taskmanager.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 trove trove'
  postrotate 'restart trove-taskmanager >/dev/null 2>&1 || true'
end

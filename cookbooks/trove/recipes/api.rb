trove_enabled = node[:openstack][:enabled_service].include?('trove')
return unless trove_enabled

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api"

api_protocol = get_api_protocol
api_host = get_api_host
auth_addr = get_auth_address

mysql_host = get_database_host
trove_password = dbpassword_for 'trove'
sql_connection = "mysql://trove:#{trove_password}@#{mysql_host}/trove"

log "sql_connection : #{sql_connection}"

template '/etc/trove/api-paste.ini' do
  source 'api-paste.ini.erb'
  user 'trove'
  group 'trove'
  mode '0644'
  variables({
    :api_protocol => api_protocol,
    :api_host => api_host,
    :auth_addr => auth_addr,
  })
end

binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

execute 'trove db sync' do
  command "#{binprefix}trove-manage --config-file=/etc/trove/trove.conf db_sync"
  user 'trove'
  group 'trove'
end

execute 'update trove datastore infomation for mysql' do
  command "#{binprefix}trove-manage --config-file=/etc/trove/trove.conf datastore_update mysql \"\" "
  user 'trove'
  group 'trove'
end

service 'trove-api' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/trove/trove.conf]'
end

logrotate_app 'trove-api' do
  cookbook 'logrotate'
  path '/var/log/trove/trove-api.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 trove trove'
  postrotate 'restart trove-api >/dev/null 2>&1 || true'
end

if check_environment_develop
  node[:trove][:enabled_databases].each do |db, dbinfo|
    dbinfo[:version].each do |version|
      bash "trove default #{db}-#{version} image register" do
        encode = "#{version.split("|")[2].to_s}-"
        encode = '' if encode.length == 1
        code <<-EOH
        TROVE_GLANCE_ID=`OS_AUTH_URL=#{auth_addr}:5000/v3 OS_USERNAME=admin OS_PROJECT_NAME=admin OS_PASSWORD=#{node[:openstack][:admin_passwd]} OS_IDENTITY_API_VERSION=3 OS_CACERT=#{node[:openstack][:old_root_pem_path]} #{binprefix}openstack image list | grep trove-kilo-#{db}-#{encode}#{version.split("|")[0].to_s} | awk '{print $2}'`
        #{binprefix}trove-manage --config-file=/etc/trove/trove.conf datastore_update #{db} ""
        #{binprefix}trove-manage --config-file=/etc/trove/trove.conf datastore_version_update #{db} #{version.include?('|') ? '\''+version+'\'' : version} #{db} $TROVE_GLANCE_ID  "" 1
        EOH
        user 'trove'
        group 'trove'
      end
      if dbinfo[:config_enable]
        bash "trove default #{db}-#{version} config parameter register" do
          code <<-EOH
          #{binprefix}trove-manage --config-file=/etc/trove/trove.conf db_load_datastore_config_parameters #{db} #{version.include?('|') ? '\''+version+'\'' : version} #{node[:openstack][:install][:source][:path]}/src/trove/trove/templates/#{db}/validation-rules.json
          EOH
          user 'trove'
          group 'trove'
        end
      end
    end
  end
end

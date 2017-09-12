::Chef::Recipe.send(:include, Kakao::Openstack)

package 'sheepdog' do
  notifies :delete, 'file[/etc/bash_completion.d/sheepdog]'
end

# completion 파일 에러로 제거 -bash: script/bash_completion_dog: No such file or directory
file '/etc/bash_completion.d/sheepdog' do
  action :nothing
end

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api"
include_recipe "#{cookbook_name}::_backend_#{node[:glance][:backend]}"

rabbit_node = nodes_by_role "openstack-rabbitmq", {:wait=>true}
mysql_host = get_database_host
memcached_node = nodes_by_role "memcached", {:wait=>true}

fail 'mysql host not found' unless mysql_host
fail 'rabbitmq node not found' if rabbit_node.empty?
fail 'memcached node not found' unless memcached_node

glance_password = dbpassword_for 'glance'

# @note glance에는 rabbit_hosts를 지정할 수 있는 옵션이 없다. 하지만 multi-master이므로 괜찮다.
# 그리고.. glance의 rabbit 사용은 notification을 사용할 때다.. ex) ceilometer
api_addr = get_api_address
auth_addr = get_auth_address

execute 'Glance: sleep' do
  command 'sleep 20s'
  action :nothing
end

sql_connection = "mysql://glance:#{glance_password}@#{mysql_host}/glance"
template '/etc/glance/glance-api.conf' do
  source 'glance-api.conf.erb'
  mode '0644'
  variables({
    :sql_connection => sql_connection,
    :rabbit_node => rabbit_node,
    :auth_addr => auth_addr,
    :api_addr => api_addr,
    :cookbook_name => cookbook_name,
    :memcached_node => memcached_node,
  })
  notifies :restart, "service[glance-api]", :immediately
  notifies :run,'execute[Glance: sleep]', :immediately
end

keystone_user 'glance' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'glance' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

service 'glance-api' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
end

include_recipe 'keystone::client'

keystone_service 'glance' do
  type 'image'
  description 'OpenStack Image Service'
  auth_addr auth_addr
end

keystone_endpoint 'glance' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:9292"
  internal_url "#{ api_addr }:9292"
  admin_url    "#{ api_addr }:9292"
  auth_addr auth_addr
end

cron 'glance-cache-cleaner' do
  minute '0'
  hour '4'
  command "#{node[:openstack][:install][:source][:path]}/bin/glance-cache-cleaner"
end

logrotate_app 'glance-api' do
  cookbook 'logrotate'
  path '/var/log/glance/api.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 glance glance'
  postrotate 'restart glance-api >/dev/null 2>&1 || true'
end

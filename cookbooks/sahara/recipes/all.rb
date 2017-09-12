sahara_enabled = node[:openstack][:enabled_service].include?('sahara')
return unless sahara_enabled

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-all"

service 'sahara-all' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/sahara/sahara.conf]'
end

auth_addr = get_auth_address
api_addr = get_api_address

# TODO: db-manage upgrade를 #{node[:openstack][:release]}로... 현재 juno 버전임에도 불구하고 head만 가능.
execute 'sahara sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"
end

keystone_user 'sahara' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'sahara' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'sahara' do
  type 'data_processing'
  description 'Sahara Data Processing'
  auth_addr auth_addr
end

keystone_endpoint 'sahara' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8386/v1.1/%(tenant_id)s"
  admin_url    "#{ api_addr }:8386/v1.1/%(tenant_id)s"
  internal_url "#{ api_addr }:8386/v1.1/%(tenant_id)s"
  auth_addr auth_addr
end

logrotate_app 'sahara-all' do
  cookbook 'logrotate'
  path '/var/log/sahara/sahara-all.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 sahara sahara'
  postrotate 'restart sahara-all >/dev/null 2>&1 || true'
end

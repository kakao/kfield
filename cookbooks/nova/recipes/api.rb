include_recipe "#{cookbook_name}::common"

# @todo 이걸 실행하려면 db connection 설정이 필요한데.. nova-conductor가 없으면 설정이 안되는군..
execute 'nova sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/nova-manage db sync"
end

include_recipe "#{cookbook_name}::install-api"

service 'nova-api' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
  subscribes :restart, 'template[/etc/nova/vendor.json]'
  subscribes :restart, 'template[/etc/nova/api-paste.ini]'
end

auth_addr = get_auth_address
api_addr = get_api_address

keystone_user 'nova' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'nova' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'nova' do
  type 'compute'
  description 'OpenStack Compute Service'
  auth_addr auth_addr
end

keystone_endpoint 'nova' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8774/v2/%(tenant_id)s"
  admin_url    "#{ api_addr }:8774/v2/%(tenant_id)s"
  internal_url "#{ api_addr }:8774/v2/%(tenant_id)s"
  auth_addr auth_addr
end

keystone_service 'ec2' do
  type 'ec2'
  description 'EC2 Compatibility Layer'
  auth_addr auth_addr
end

keystone_endpoint 'ec2' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8773/service/Cloud"
  admin_url    "#{ api_addr }:8773/service/Cloud/Admin"
  internal_url "#{ api_addr }:8773/service/Cloud"
  auth_addr auth_addr
end

logrotate_app 'nova-api' do
  cookbook 'logrotate'
  path '/var/log/nova/nova-api.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 nova nova'
  postrotate 'restart nova-api >/dev/null 2>&1 || true'
end

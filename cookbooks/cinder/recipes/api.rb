return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api"

service 'cinder-api' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/cinder/cinder.conf]"
  subscribes :restart, "template[/etc/cinder/api-paste.ini]"
end

# create cinder service / endpoint
auth_addr = get_auth_address
api_addr = get_api_address

keystone_user 'cinder' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'cinder' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'cinder' do
  type 'volume'
  description 'OpenStack Block Storage'
  auth_addr auth_addr
end

keystone_endpoint 'cinder' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8776/v1/%(tenant_id)s"
  admin_url    "#{ api_addr }:8776/v1/%(tenant_id)s"
  internal_url "#{ api_addr }:8776/v1/%(tenant_id)s"
  auth_addr auth_addr
end

keystone_service 'cinderv2' do
  type 'volumev2'
  description 'OpenStack Block Storage v2'
  auth_addr auth_addr
end

keystone_endpoint 'cinderv2' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8776/v2/%(tenant_id)s"
  admin_url    "#{ api_addr }:8776/v2/%(tenant_id)s"
  internal_url "#{ api_addr }:8776/v2/%(tenant_id)s"
  auth_addr auth_addr
end

# logrotate
logrotate_app 'cinder-api' do
  cookbook 'logrotate'
  path '/var/log/cinder/cinder-api.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 cinder cinder'
  postrotate 'restart cinder-api >/dev/null 2>&1 || true'
end

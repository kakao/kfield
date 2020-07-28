return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api"

service 'heat-api' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/heat/heat.conf]'
end

auth_addr = get_auth_address
api_addr = get_api_address

# create heat domain & domain_admin_user granted as admin
keystone_domain node[:heat][:stack_user_domain_name] do
  domain_name node[:heat][:stack_user_domain_name]
  auth_addr auth_addr
end

keystone_domain_user node[:heat][:stack_domain_admin] do
  domain_name node[:heat][:stack_user_domain_name]
  domain_admin_name node[:heat][:stack_domain_admin]
  domain_admin_password node[:heat][:stack_domain_admin_password]
  auth_addr auth_addr
end

keystone_user 'heat' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'heat' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'heat' do
  type 'orchestration'
  description 'Heat Orchestration API'
  auth_addr auth_addr
end

keystone_endpoint 'heat' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8004/v1/%(tenant_id)s"
  admin_url    "#{ api_addr }:8004/v1/%(tenant_id)s"
  internal_url "#{ api_addr }:8004/v1/%(tenant_id)s"
  auth_addr auth_addr
end

logrotate_app 'heat-api' do
  cookbook 'logrotate'
  path '/var/log/heat/heat-api.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 heat heat'
  postrotate 'restart heat-api >/dev/null 2>&1 || true'
end

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api-cfn"

service 'heat-api-cfn' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/heat/heat.conf]'
end

auth_addr = get_auth_address
api_addr = get_api_address

keystone_service 'heat-cfn' do
  type 'cloudformation'
  description 'Heat CloudFormation API'
  auth_addr auth_addr
end

keystone_endpoint 'heat-cfn' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8000/v1"
  admin_url    "#{ api_addr }:8000/v1"
  internal_url "#{ api_addr }:8000/v1"
  auth_addr auth_addr
end

logrotate_app 'heat-cfn' do
  cookbook 'logrotate'
  path '/var/log/heat/heat-cfn.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 heat heat'
  postrotate 'restart heat-cfn >/dev/null 2>&1 || true'
end

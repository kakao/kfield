return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-api"

ceilometer_enabled = node[:openstack][:enabled_service].include?('ceilometer')

service 'ceilometer-api' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action ceilometer_enabled ? [ :enable, :start ] : [ :disable, :stop ]
  subscribes :restart, "template[/etc/ceilometer/ceilometer.conf]"
  subscribes :restart, "template[/etc/ceilometer/pipeline.yaml]"
end

return unless ceilometer_enabled

auth_addr = get_auth_address
api_addr = get_api_address

keystone_user 'ceilometer' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'ceilometer' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'ceilometer' do
  type 'metering'
  description 'Ceilometer Telemetry Service'
  auth_addr auth_addr
end

keystone_endpoint 'ceilometer' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:8777/"
  admin_url    "#{ api_addr }:8777/"
  internal_url "#{ api_addr }:8777/"
  auth_addr auth_addr
end

# logrotate
logrotate_app 'ceilometer-api' do
  cookbook 'logrotate'
  path '/var/log/ceilometer/ceilometer-api.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 ceilometer ceilometer'
  postrotate 'restart ceilometer-api >/dev/null 2>&1 || true'
end

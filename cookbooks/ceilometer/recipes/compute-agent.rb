return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-agent-compute"

ceilometer_enabled = node[:openstack][:enabled_service].include?('ceilometer')

service 'ceilometer-agent-compute' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action ceilometer_enabled ? [ :enable, :start ] : [ :disable, :stop ]
  subscribes :restart, "template[/etc/ceilometer/ceilometer.conf]"
  subscribes :restart, "template[/etc/ceilometer/pipeline.yaml]"
end

# logrotate
logrotate_app 'ceilometer-agent-compute' do
  cookbook 'logrotate'
  path '/var/log/ceilometer/ceilometer-agent-compute.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 ceilometer ceilometer'
  postrotate 'restart ceilometer-agent-compute >/dev/null 2>&1 || true'
end

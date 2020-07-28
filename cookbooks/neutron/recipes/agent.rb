::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::common"

sysctl_param 'net.ipv4.ip_forward' do
  value 1
end

sysctl_param 'net.ipv4.conf.all.rp_filter' do
  value 0
end

sysctl_param 'net.ipv4.conf.default.rp_filter' do
  value 0
end

include_recipe "#{cookbook_name}::plugin-#{node[:neutron][:plugin_agent]}-agent"

# neutron agent가 만들어내는 auth.log filtering
# see http://blog.woosum.net/archives/1337
# https://jira.your.com/browse/ITF-339
filter = <<-EOT
:msg, regex, "neutron .* USER=root" ~
EOT

execute 'add neutron-agent syslog filter' do
  command "sed -i '4i#{filter}' /etc/rsyslog.d/50-default.conf"
  not_if "grep neutron /etc/rsyslog.d/50-default.conf"
  notifies :restart, "service[rsyslog]"
end

service "rsyslog" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

logrotate_app "neutron-plugin-#{node[:neutron][:plugin_agent]}-agent" do
  cookbook 'logrotate'
  path "/var/log/neutron/#{node[:neutron][:plugin_agent]}-agent.log"
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 neutron neutron'
  postrotate "restart neutron-plugin-#{node[:neutron][:plugin_agent]}-agent >/dev/null 2>&1 || true"
end


package 'bridge-utils'

include_recipe "#{cookbook_name}::install-plugin-#{node[:neutron][:plugin_agent]}-agent"
include_recipe "#{cookbook_name}::_agent_#{node[:neutron][:tenant_network_type]}"

# @fixme 이 파일이 변경되어 restart를 날리는데.. 실제 프로레스는 HUP 시그널만 가서 설정을 읽지 않는 듯...
template '/etc/init/neutron-plugin-linuxbridge-agent.conf' do
  source 'neutron-plugin-linuxbridge-agent.conf.erb'
  notifies :run, "execute[neutron-plugin-linuxbridge-agent]"
end

execute 'neutron-plugin-linuxbridge-agent' do
  action :nothing
  command 'service neutron-plugin-linuxbridge-agent restart'
end

service 'neutron-plugin-linuxbridge-agent' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/neutron/neutron.conf]"
  subscribes :restart, "template[/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini]"
  subscribes :restart, "link[/etc/neutron/plugins/plugin.ini]"
end

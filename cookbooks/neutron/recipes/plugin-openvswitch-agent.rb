
package 'openvswitch-switch'
service 'openvswitch-switch' do
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
end

package "linux-headers-`uname -r`"
package 'openvswitch-datapath-dkms' do
  notifies :restart, 'service[openvswitch-switch]', :immediately
end

include_recipe "#{cookbook_name}::install-plugin-#{node[:neutron][:plugin_agent]}-agent"
include_recipe "#{cookbook_name}::_agent_#{node[:neutron][:tenant_network_type]}"

# @fixme 이 파일이 변경되어 restart를 날리는데.. 실제 프로레스는 HUP 시그널만 가서 설정을 읽지 않는 듯...
template '/etc/init/neutron-plugin-openvswitch-agent.conf' do
  source 'neutron-plugin-openvswitch-agent.conf.erb'
  notifies :run, "execute[neutron-plugin-openvswitch-agent]"
end

execute 'neutron-plugin-openvswitch-agent' do
  action :nothing
  command 'service neutron-plugin-openvswitch-agent restart'
end

# integration bridge
execute "add #{node[:neutron][:integration_bridge]}" do
  command "ovs-vsctl add-br #{node[:neutron][:integration_bridge]}"
  not_if "ovs-vsctl br-exists #{node[:neutron][:integration_bridge]}"
end

service 'neutron-plugin-openvswitch-agent' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/neutron/neutron.conf]"
  subscribes :restart, "template[/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini]"
  subscribes :restart, "link[/etc/neutron/plugins/plugin.ini]"
end

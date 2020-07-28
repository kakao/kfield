# ubuntu의 패키지 의존성에 neutron-l3-agent를 설치하면 neutron-metadata-agent가 걸려있다.
# 따라서 우선간 neutron-l3-agent, neutron-dhcp-agent, neutron-metadata-agent는 같은 서버로 간다.
include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-l3-agent"

execute 'create br-ex' do
  command 'brctl addbr br-ex'
  not_if 'brctl show|grep br-ex'
end

template '/etc/neutron/l3_agent.ini' do
  source 'l3_agent.ini.erb'
  mode '0644'
end

service 'neutron-l3-agent' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/neutron/neutron.conf]"
  subscribes :restart, "template[/etc/neutron/l3_agent.ini]"
end

logrotate_app 'neutron-l3-agent' do
  cookbook 'logrotate'
  path '/var/log/neutron/l3-agent.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 neutron neutron'
  postrotate 'restart neutron-l3-agent >/dev/null 2>&1 || true'
end

include_recipe "#{cookbook_name}::common"
include_recipe "#{cookbook_name}::install-server"

template '/etc/default/neutron-server' do
  source 'neutron-server.erb'
end

template '/etc/init/neutron-server.conf' do
  source 'neutron-server.conf.erb'
  notifies :run, 'execute[neutron-server restart]'
end

execute 'neutron-server restart' do
  action :nothing
  command 'service neutron-server restart'
end

service 'neutron-server' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
  subscribes :restart, "template[/etc/neutron/neutron.conf]"
  subscribes :restart, "template[/etc/neutron/api-paste.ini]"
  subscribes :restart, "template[/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini]"
  subscribes :restart, "template[/etc/default/neutron-server]"
  subscribes :restart, "template[/etc/init/neutron-server.conf]"
end

execute 'neutron sync' do
  command "#{node[:openstack][:install][:source][:path]}/bin/neutron-db-manage upgrade #{node[:openstack][:release]}"
end

if node[:neutron][:lbaas][:enable] == true && node[:openstack][:release] == 'kilo'
  execute 'neutron lbaas db sync' do
    command "#{node[:openstack][:install][:source][:path]}/bin/neutron-db-manage --service lbaas upgrade #{node[:openstack][:release]}"
  end
end

if node[:neutron][:fwaas][:enable] == true && node[:openstack][:release] == 'kilo'
  execute 'neutron fwaas db sync' do
    command "#{node[:openstack][:install][:source][:path]}/bin/neutron-db-manage --service fwaas upgrade #{node[:openstack][:release]}"
  end
end

auth_addr = get_auth_address
api_addr = get_api_address

keystone_user 'neutron' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'neutron' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'neutron' do
  type 'network'
  description 'OpenStack Networking Service'
  auth_addr auth_addr
end

keystone_endpoint 'neutron' do
  region node[:openstack][:region_name]
  public_url   "#{ api_addr }:9696"
  internal_url "#{ api_addr }:9696"
  admin_url    "#{ api_addr }:9696"
  auth_addr auth_addr
end

logrotate_app 'neutron-server' do
  cookbook 'logrotate'
  path '/var/log/neutron/server.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 neutron neutron'
  postrotate 'restart neutron-server >/dev/null 2>&1 || true'
end

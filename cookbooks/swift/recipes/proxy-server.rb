#
# Cookbook Name:: swift
# Recipe:: proxy-server
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe 'swift::common'
include_recipe 'memcached'

service = 'proxy'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

memcache_servers = []
proxy_role = 'swift-proxy'
proxy_nodes = search(:node, "chef_environment:#{node.chef_environment} AND roles:#{proxy_role}")
proxy_nodes << node
proxy_nodes.uniq.sort.each do |proxy|
  proxy_ip = proxy['ipaddress']
  next unless proxy_ip # skip nil ips so we dont break the config
  server_str = "#{proxy_ip}:11211"
  memcache_servers << server_str unless memcache_servers.include?(server_str)
end

protocol = node.recipe?('swift::reverse-proxy') ? 'https' : 'http'
auth_host = get_auth_host
auth_protocol = get_auth_protocol
auth_addr = get_auth_address

# create proxy config file
template '/etc/swift/proxy-server.conf' do
  source 'proxy-server.conf.erb'
  owner 'root'
  group 'swift'
  mode '0640'
  variables({
    :memcache_servers => memcache_servers,
    # true if usage for anonymous referrers ('.r:*').
    :delay_auth_decision => true,
    :auth_host => auth_host,
    :auth_protocol => auth_protocol,
    :auth_addr => auth_addr,
  })
  notifies :reload, 'service[swift-proxy]'
end

service 'swift-proxy' do
  supports status: true, restart: true, reload: true
  action [:enable, :start]
  reload_command "#{node[:openstack][:install][:source][:path]}/bin/swift-init proxy reload"
  only_if '[ -e /etc/swift/proxy-server.conf ] && [ -e /etc/swift/object.ring.gz ]'
end

wait_role 'openstack-keystone' if (node[:openstack][:regions].nil? and node[:openstack][:region_name].nil?)

keystone_user 'swift' do
  password node[:openstack][:service_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_user_role 'swift' do
  tenant 'service'
  role 'admin'
  auth_addr auth_addr
end

keystone_service 'swift' do
  type 'object-store'
  description 'OpenStack Object Storage'
  auth_addr auth_addr
end

keystone_endpoint 'swift' do
  region node[:openstack][:region_name]
  public_url   "#{protocol}://#{node[:swift][:domain]}/v1/AUTH_%(tenant_id)s"
  admin_url    "#{protocol}://#{node[:swift][:domain]}"
  internal_url "#{protocol}://#{node[:swift][:domain]}/v1/AUTH_%(tenant_id)s"
  auth_addr auth_addr
end

cookbook_file '/etc/rsyslog.d/10-swift-proxy.conf' do
  mode '0644'
  source '10-swift-proxy.conf'
  notifies :run, 'execute[service rsyslog restart]'
end

template '/etc/swift/dispersion.conf' do
  source 'dispersion.conf.erb'
  owner 'root'
  group 'swift'
  mode '0640'
  variables({
    :auth_protocol => auth_protocol,
    :auth_host => auth_host,
  })
end

logrotate_app 'proxy' do
    cookbook 'logrotate'
    path ['/var/log/swift/proxy.log', '/var/log/swift/proxy.error']
    options ['compress', 'missingok', 'delaycompress', 'notifempty']
    frequency node[:logrotate][:openstack][:frequency]
    rotate node[:logrotate][:openstack][:rotate]
    create '644 syslog adm'
    postrotate 'service rsyslog restart >/dev/null 2>&1 || true'
end

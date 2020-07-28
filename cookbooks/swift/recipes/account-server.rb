#
# Cookbook Name:: swift
# Recipe:: account-server
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe 'swift::storage-server'

template '/etc/init/swift-account.conf' do
  source 'init-swift-account.conf.erb'
end

link '/etc/init.d/swift-account' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-account-auditor.conf' do
  source 'init-swift-account-auditor.conf.erb'
end

link '/etc/init.d/swift-account-auditor' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-account-reaper.conf' do
  source 'init-swift-account-reaper.conf.erb'
end

link '/etc/init.d/swift-account-reaper' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-account-replicator.conf' do
  source 'init-swift-account-replicator.conf.erb'
end

link '/etc/init.d/swift-account-replicator' do
  to '/lib/init/upstart-job'
end

template '/etc/swift/account-server.conf' do
  source 'account-server.conf.erb'
  owner 'root'
  group 'swift'
  mode '0640'
  notifies :reload, 'service[swift-account]'
  notifies :reload, 'service[swift-account-auditor]'
  notifies :reload, 'service[swift-account-reaper]'
  notifies :reload, 'service[swift-account-replicator]'
end

%w{account account-auditor account-reaper account-replicator}.each do |svc|
  service "swift-#{svc}" do
    supports status: true, restart: true, reload: true
    action [:enable, :start]
    reload_command "#{node[:openstack][:install][:source][:path]}/bin/swift-init #{svc} reload"
    only_if '[ -e /etc/swift/account-server.conf ] && [ -e /etc/swift/account.ring.gz ]'
  end
end

cookbook_file '/etc/rsyslog.d/10-swift-account.conf' do
  mode '0644'
  source '10-swift-account.conf'
  notifies :run, 'execute[service rsyslog restart]'
end

logrotate_app 'account' do
    cookbook 'logrotate'
    path ['/var/log/swift/account.log', '/var/log/swift/account.error']
    options ['compress', 'missingok', 'delaycompress', 'notifempty']
    frequency node[:logrotate][:openstack][:frequency]
    rotate node[:logrotate][:openstack][:rotate]
    create '644 syslog adm'
    postrotate 'service rsyslog restart >/dev/null 2>&1 || true'
end

cookbook_file '/etc/rsyslog.d/10-swift-daemon.conf' do
  mode '0644'
  source '10-swift-daemon.conf'
  notifies :run, 'execute[service rsyslog restart]'
end

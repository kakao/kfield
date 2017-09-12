#
# Cookbook Name:: swift
# Recipe:: container-server
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe 'swift::storage-server'

template '/etc/init/swift-container.conf' do
  source 'init-swift-container.conf.erb'
end

link '/etc/init.d/swift-container' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-container-auditor.conf' do
  source 'init-swift-container-auditor.conf.erb'
end

link '/etc/init.d/swift-container-auditor' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-container-replicator.conf' do
  source 'init-swift-container-replicator.conf.erb'
end

link '/etc/init.d/swift-container-replicator' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-container-sync.conf' do
  source 'init-swift-container-sync.conf.erb'
end

link '/etc/init.d/swift-container-sync' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-container-updater.conf' do
  source 'init-swift-container-updater.conf.erb'
end

link '/etc/init.d/swift-container-updater' do
  to '/lib/init/upstart-job'
end

template '/etc/swift/container-server.conf' do
  source 'container-server.conf.erb'
  owner 'root'
  group 'swift'
  mode '0640'
  notifies :reload, 'service[swift-container]'
  notifies :reload, 'service[swift-container-replicator]'
  notifies :reload, 'service[swift-container-updater]'
  notifies :reload, 'service[swift-container-auditor]'
end

%w{container container-auditor container-replicator container-updater}.each do |svc|
  service "swift-#{svc}" do
    supports status: true, restart: true, reload: true
    action [:enable, :start]
    reload_command "#{node[:openstack][:install][:source][:path]}/bin/swift-init #{svc} reload"
    only_if '[ -e /etc/swift/container-server.conf ] && [ -e /etc/swift/container.ring.gz ]'
  end
end

cookbook_file '/etc/rsyslog.d/10-swift-container.conf' do
  mode '0644'
  source '10-swift-container.conf'
  notifies :run, 'execute[service rsyslog restart]'
end

logrotate_app 'container' do
    cookbook 'logrotate'
    path ['/var/log/swift/container.log', '/var/log/swift/container.error']
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

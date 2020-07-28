#
# Cookbook Name:: swift
# Recipe:: object-server
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe 'swift::storage-server'

template '/etc/init/swift-object.conf' do
  source 'init-swift-object.conf.erb'
end

link '/etc/init.d/swift-object' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-object-auditor.conf' do
  source 'init-swift-object-auditor.conf.erb'
end

link '/etc/init.d/swift-object-auditor' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-object-replicator.conf' do
  source 'init-swift-object-replicator.conf.erb'
end

link '/etc/init.d/swift-object-replicator' do
  to '/lib/init/upstart-job'
end

template '/etc/init/swift-object-updater.conf' do
  source 'init-swift-object-updater.conf.erb'
end

link '/etc/init.d/swift-object-updater' do
  to '/lib/init/upstart-job'
end

template '/etc/swift/object-server.conf' do
  source 'object-server.conf.erb'
  owner 'root'
  group 'swift'
  mode '0640'
  notifies :reload, 'service[swift-object]', :immediately
  notifies :reload, 'service[swift-object-replicator]', :immediately
  notifies :reload, 'service[swift-object-updater]', :immediately
  notifies :reload, 'service[swift-object-auditor]', :immediately
end

%w{object object-replicator object-auditor object-updater}.each do |svc|
  service "swift-#{svc}" do
    supports status: true, restart: true, reload: true
    action [:enable, :start]
    reload_command "#{node[:openstack][:install][:source][:path]}/bin/swift-init #{svc} reload"
    only_if '[ -e /etc/swift/object-server.conf ] && [ -e /etc/swift/object.ring.gz ]'
  end
end

cron 'swift-recon' do
  minute '*/5'
  command 'test ! -f /etc/swift/object.ring.gz || swift-recon-cron /etc/swift/object-server.conf'
  user 'swift'
end

cookbook_file '/etc/rsyslog.d/10-swift-object.conf' do
  mode '0644'
  source '10-swift-object.conf'
  notifies :run, 'execute[service rsyslog restart]'
end

logrotate_app 'object' do
    cookbook 'logrotate'
    path ['/var/log/swift/object.log', '/var/log/swift/object.error']
    options ['compress', 'missingok', 'delaycompress', 'notifempty']
    frequency 'weekly'
    rotate 30
    create '644 syslog adm'
    postrotate 'service rsyslog restart >/dev/null 2>&1 || true'
end

cookbook_file '/etc/rsyslog.d/10-swift-daemon.conf' do
  mode '0644'
  source '10-swift-daemon.conf'
  notifies :run, 'execute[service rsyslog restart]'
end

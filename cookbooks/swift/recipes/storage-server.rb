#
# Cookbook Name:: swift
# Recipe:: storage-server
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

include_recipe 'swift::common'
include_recipe 'swift::rsync'
include_recipe 'swift::disk'

template '/etc/swift/drive-audit.conf' do
  source 'drive-audit.conf.erb'
  owner 'root'
  group 'swift'
  mode '0640'
end

cron 'drive-audit' do
  hour node['swift']['storage_server']['audit_hour']
  minute '10'
  command 'swift-drive-audit /etc/swift/drive-audit.conf'
end

logrotate_app 'daemon' do
    cookbook 'logrotate'
    path ['/var/log/swift/daemon.log', '/var/log/swift/daemon.error']
    options ['compress', 'missingok', 'delaycompress', 'notifempty']
    frequency node[:logrotate][:openstack][:frequency]
    rotate node[:logrotate][:openstack][:rotate]
    create '644 syslog adm'
    postrotate 'service rsyslog restart >/dev/null 2>&1 || true'
end

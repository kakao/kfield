#
# Cookbook Name:: swift
# Recipe:: rsync
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

package 'rsync' do
  options "-o Dpkg::Options:='--force-confold' -o Dpkg::Option:='--force-confdef'"
end

service 'rsync' do
  supports status: false, restart: true
  action [:enable, :start]
  only_if '[ -f /etc/rsyncd.conf ]'
end

template '/etc/rsyncd.conf' do
  source 'rsyncd.conf.erb'
  mode '0644'
  notifies :restart, "service[rsync]", :immediately
end

execute 'enable rsync' do
  command "sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync"
  only_if "grep -q 'RSYNC_ENABLE=false' /etc/default/rsync"
  notifies :restart, 'service[rsync]', :immediately
  action :run
end

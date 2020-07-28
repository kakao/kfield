#
# Cookbook Name:: swift
# Recipe:: common
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

# sysctl setting ref: http://docs.openstack.org/developer/swift/deployment_guide.html#general-system-tuning
sysctl_param 'net.ipv4.tcp_tw_recycle' do
  value 1
end

sysctl_param 'net.ipv4.tcp_tw_reuse' do
  value 1
end

sysctl_param 'net.ipv4.tcp_syncookies' do
  value 0
end

# swift 의 uid, gid를 고정하지 않으면 나중에 jbod 단위로 구조 변경때 고생을 한다.
# jbod를 다른 서버로 옮기면 uid, gid 때문에 모든 파일을 읽지 못하는 문제가..
user 'swift' do
  uid node['swift']['owner']['user']['id']
  system true
  shell '/bin/false'
end

group 'swift' do
  gid node['swift']['owner']['group']['id']
  members 'swift'
  system true
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"

git source_path do
  repository node[:openstack][:github][cookbook_name.to_sym][:url]
  revision node[:openstack][:github][cookbook_name.to_sym][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
  retries 5
  retry_delay 5
end

python_pip source_path do
  virtualenv node[:openstack][:install][:source][:path]
  options '-e'
  action :nothing
  retries 5
  retry_delay 5
end

directory '/etc/swift' do
  owner 'root'
  group 'swift'
  mode '0750'
end

swifthashprefix = node['swift']['hash']['prefix']
swifthashsuffix = node['swift']['hash']['suffix']

Chef::Log.warn 'Change your hash prefix' if swifthashprefix == 'changeme'
Chef::Log.warn 'Change your hash suffix' if swifthashsuffix == 'changeme'

content = "[swift-hash]
swift_hash_path_prefix=#{swifthashprefix}
swift_hash_path_suffix=#{swifthashsuffix}

[swift-path]
path = #{node[:openstack][:install][:source][:path]}/bin
"

file '/etc/swift/swift.conf' do
  owner 'root'
  group 'swift'
  mode '0640'
  content content
end

# http://docs.openstack.org/security-guide/content/ch027_storage.html#ch027_storage-idpC1
bash 'setup file permisson' do
  code <<-EOC
  chown -R root:swift /etc/swift/*
  find /etc/swift/ -type f -exec chmod 640 {} \\;
  find /etc/swift/ -type d -exec chmod 750 {} \\;
EOC
  only_if 'test -d /etc/swift'
end

directory '/var/cache/swift' do
  group 'root'
  owner 'swift'
  recursive true
  mode '0775'
end

execute 'service rsyslog restart' do
  action :nothing
end

directory '/var/log/swift' do
  group 'adm'
  owner 'syslog'
  recursive true
  mode '0775'
  notifies :run, 'execute[service rsyslog restart]'
end

execute 'enable rsync' do
  command "sed -i 's/$PrivDropToGroup syslog/$PrivDropToGroup adm/g' /etc/rsyslog.conf"
  only_if "grep -q '$PrivDropToGroup syslog' /etc/rsyslog.conf"
  notifies :run, 'execute[service rsyslog restart]'
end

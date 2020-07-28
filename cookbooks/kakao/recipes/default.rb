#
# Cookbook Name:: kakao
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute 'tb conf ntp config' do
  only_if 'which tb'
end

# @todo 이건 뭔가 나이스한 방법이 있을텐데...
# apt-get 패키지 인덱스 업데이트를 주기적으로 수행...
case node[:platform]
when 'ubuntu'
  include_recipe 'apt::default'

  if check_environment_jenkins
    execute 'apt-get update' do
      action :nothing
    end.run_action(:run)
  end
end

include_recipe 'ohai::default'

ohai 'dkohai_reload' do
  action :nothing
end

template "#{node[:ohai][:plugin_path]}/dkohai.rb" do
  source 'dkohai.rb'
  notifies :reload, 'ohai[dkohai_reload]'
end

bash 'dont forward log to splunk' do
  code <<-EOH
  sed -i '/@suzy001.kr.your.com/d' /etc/rsyslog.conf && service rsyslog restart
EOH
  not_if { check_environment_production }
end

# authorized_keys를 설정하는 cookbook 중에 맘에 드는 게 없음
# requirements:
#   - chef로 설정하지 않은 key도 유지해야 함...
#   - comment도 유지해아함.
%w(root vagrant).each do |user|
  next unless node['etc']['passwd'].include? user

  home_dir = node['etc']['passwd'][user]['dir']

  directory "#{ home_dir }/.ssh" do
    owner node['etc']['passwd'][user]['uid']
    group node['etc']['passwd'][user]['gid']
    mode 0700
  end.run_action(:create)

  execute "touch #{ home_dir }/.ssh/authorized_keys" do
    action :nothing
    not_if { File.exist?("#{ home_dir }/.ssh/authorized_keys") }
  end.run_action(:run)

  node[:kakao][:ssh_key].each do |_, v|
    f = Chef::Util::FileEdit.new("#{ home_dir }/.ssh/authorized_keys")
    f.insert_line_if_no_match(/#{v}/, v)
    f.write_file
  end
end

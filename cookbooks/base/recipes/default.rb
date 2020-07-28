# @todo base cookbook이 만들어지면 OpenStack에 있는 라이브러리들이 여기로 옮기는게 맞을까?
::Chef::Recipe.send(:include, Kakao::Openstack)

# disable unattended upgrade
cookbook_file '/etc/apt/apt.conf.d/20auto-upgrades' do
  source '20auto-upgrades'
  user 'root'
  group 'root'
  mode 00644
end

# 개발환경에서 로그 모으기
if !check_environment_production && !node_by_role('logstash_server').nil?
  node.override[:rsyslog][:port] = 5959
  node.override[:rsyslog][:server_serarch] = 'role:logstash_server'
  include_recipe 'rsyslog::client' unless node_by_role('logstash_server')[:fqdn] == node[:fqdn]
else
  file '/etc/rsyslog.d/49-remote.conf' do
    action :delete
    notifies :run, 'bash[restart rsyslog]'
  end

  bash 'restart rsyslog' do
    code 'service rsyslog restart'
    action :nothing
  end
end

%w(knife-lastrun).each do |g|
  chef_gem "#{g}" do
    action :nothing
  end.run_action(:install)
end

if check_environment_production
  # chef handler
  include_recipe 'chef_handler'

  handler_path = node['chef_handler']['handler_path']
  handler = ::File.join handler_path, 'talk_handler.rb'

  template "#{handler}" do
    source 'talk_handler.erb'
    variables(:room => node[:base][:talk_handler][:room])
    action :nothing
  end.run_action(:create)

end

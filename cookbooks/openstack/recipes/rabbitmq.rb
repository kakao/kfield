::Chef::Recipe.send(:include, Kakao::Openstack)

user = node[:rabbitmq][:default_user]
pass = node[:rabbitmq][:default_pass]
vhost = node[:rabbitmq][:default_vhost]

clusters = nodes_by_role "openstack-rabbitmq"

if !clusters.nil?
  node.override['rabbitmq']['cluster_disk_nodes'] = clusters.map do |n|
    "rabbit@#{n['hostname']}"
  end.sort
  node.override['rabbitmq']['clustering']['cluster_nodes'] = clusters.map do |n|
    { :name => "rabbit@#{n['name']}", :type => 'disc' }
  end.sort_by{|v| v[:name]}
  node.override[:rabbitmq][:cluster] = clusters.length > 1
  if clusters.length > 1
    node.override['rabbitmq']['clustering']['use_auto_clustering'] = true
    node.override['rabbitmq']['clustering']['cluster_name'] = 'openstack'
  end
else
  node.override[:rabbitmq][:cluster] = false
end

include_recipe 'rabbitmq'
include_recipe 'rabbitmq::mgmt_console'

rabbitmq_user 'remove rabbit guest user' do
  user 'guest'
  action :delete
  not_if { user == 'guest' }
end

rabbitmq_user 'add openstack rabbit user' do
  user user
  password pass
  action :add
end

rabbitmq_user 'change openstack rabbit user password' do
  user user
  password pass
  action :change_password
end

rabbitmq_vhost vhost do
  action :add
end

rabbitmq_user 'set openstack user permissions' do
  user user
  vhost vhost
  permissions '.* .* .*'
  action :set_permissions
end

rabbitmq_user 'set rabbit administrator tag' do
  user user
  tag 'administrator'
  action :set_tags
end

# mirrored queue
rabbitmq_policy 'set mirrored queue' do
  name 'HA'
  pattern "^(?!amq\\.).*"
  params ({"ha-mode"=>"all"})
end

template '/usr/local/bin/rabbitmqadmin' do
  source 'rabbitmqadmin.erb'
  mode 00755
end

# bash completion for rabbitmqadmin
rabbit_completion = '/etc/bash_completion.d/rabbitmqadmin'
bash 'install bash completion for rabbitmqadmin' do
  code <<-EOH
  rabbitmqadmin --bash-completion > /etc/bash_completion.d/rabbitmqadmin
EOH
  not_if { File.exists?(rabbit_completion) }
end

if check_environment_production
  template '/root/watchrabbitmq.sh' do
    source 'watchrabbitmq.sh.erb'
    mode 00755
  end

  cron 'rabbitmq-queue-watcher' do
    minute '10'
    command '/root/watchrabbitmq.sh'
  end
end

execute 'rabbit: restart' do
  command 'service rabbitmq-server restart '
  only_if { check_environment_jenkins }
end

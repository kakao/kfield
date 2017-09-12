# package "#{cookbook_name}"
user cookbook_name do
  system true
  home "/var/lib/#{cookbook_name}"
  supports :manage_home => false
  shell '/bin/false'
end

group cookbook_name do
  system true
  members cookbook_name
end

directory "/var/lib/#{cookbook_name}/" do
  recursive true
  owner cookbook_name
  group cookbook_name
  mode '0700'
end

%W[
  /etc/#{cookbook_name}/
  /var/log/#{cookbook_name}/
].each do |path|
  directory path do
    recursive true
    owner cookbook_name
    group cookbook_name
    mode '0755'
  end
end

package 'mysql-client'
package 'libmysqlclient-dev'

# 만약 sql을 쓴다면 필요
python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

python_pip 'python-memcached' do
  virtualenv node[:openstack][:install][:source][:path]
  only_if { node[:keystone][:token_driver] == 'memcache' }
end
# 만약 sql을 쓴다면 필요

package 'libxslt1-dev' # lxml>=2.3 (from keystone==2014.1.4.dev3.g35d937d)
package 'libyaml-dev' # PyYAML>=3.1.0 (from oslo.messaging>=1.3.0->keystone==2014.1.4.dev3.g35d937d)

# package "python-#{cookbook_name}"
source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
git source_path do
  repository node[:openstack][:github][cookbook_name.to_sym][:url]
  revision node[:openstack][:github][cookbook_name.to_sym][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
  notifies :run, "bash[install #{cookbook_name} config]", :immediately
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

# install binary, config

template '/etc/init/keystone.conf' do
  source 'init-keystone.conf.erb'
end

link "/etc/init.d/#{cookbook_name}" do
  to '/lib/init/upstart-job'
end

# 소스안에 config path가 ./etc/ ...
bash "install #{cookbook_name} config" do
  code <<-EOH
    cp #{source_path}/etc/default_catalog.templates /etc/#{cookbook_name}/default_catalog.templates
    cp #{source_path}/etc/keystone-paste.ini /etc/#{cookbook_name}/keystone-paste.ini
    cp #{source_path}/etc/policy.json /etc/#{cookbook_name}/policy.json
  EOH
  action :nothing
end

cookbook_file "/etc/#{cookbook_name}/logging.conf" do
  source 'logging.conf'
end

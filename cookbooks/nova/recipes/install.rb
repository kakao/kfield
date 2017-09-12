source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"

# package "#{cookbook_name}-common"
user cookbook_name do
  system true
  home node[:nova][:state_path]
  supports :manage_home => false
  shell '/bin/false'
end

group cookbook_name do
  system true
  members cookbook_name
end

directory "/var/log/#{cookbook_name}/" do
  owner cookbook_name
  group 'adm'
  mode '0755'
end

directory "/etc/#{cookbook_name}/" do
  owner cookbook_name
  group cookbook_name
  mode '0755'
end

%W[
  #{node[:nova][:state_path]}
  #{node[:nova][:state_path]}/networks/
  #{node[:nova][:state_path]}/keys/
  #{node[:nova][:state_path]}/instances/
  #{node[:nova][:state_path]}/images/
  #{node[:nova][:state_path]}/buckets/
  #{node[:nova][:state_path]}/CA/
  #{node[:nova][:state_path]}/CA/newcerts/
  #{node[:nova][:state_path]}/CA/INTER/
  #{node[:nova][:state_path]}/CA/reqs/
  #{node[:nova][:state_path]}/CA/private/
  #{node[:nova][:state_path]}/tmp/
].each do |path|
  directory path do
    owner cookbook_name
    group cookbook_name
    mode '0755'
  end
end

directory "/etc/#{cookbook_name}/rootwrap.d" do
  mode '0755'
end

package 'libxslt1-dev' # lxml>=2.3 (from nova==2014.1.4.dev45.g3dcdce3)
package 'libyaml-dev'# PyYAML>=3.1.0 (from oslo.messaging>=1.3.0->nova==2014.1.4.dev45.g3dcdce3)
package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->python-glanceclient>=0.9.0->nova==2014.1.4.dev45.g3dcdce3)

# package "python-#{cookbook_name}"
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

bash "install #{cookbook_name} config" do
  code <<-EOH
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.conf /etc/#{cookbook_name}/rootwrap.conf
    cp #{source_path}/etc/#{cookbook_name}/api-paste.ini /etc/#{cookbook_name}/api-paste.ini
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/api-paste.ini
    chmod 640 /etc/#{cookbook_name}/api-paste.ini
EOH
  action :nothing
end

template "/etc/#{cookbook_name}/policy.json" do
  source 'policy.json.erb'
  mode '0640'
  owner cookbook_name
  group cookbook_name
end

# 소스의 logging_sample.conf 와 동일 하긴 하지만 nova빼고 나머지 모든 소스가 달라서 이것도 그냥 이렇게..
cookbook_file "/etc/#{cookbook_name}/logging.conf" do
  source 'logging.conf'
  owner cookbook_name
  group cookbook_name
end

template "/etc/sudoers.d/#{cookbook_name}_sudoers" do
  source "#{cookbook_name}_sudoers.erb"
  mode '0440'
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"

# package "#{cookbook_name}-common"
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

directory "/etc/#{cookbook_name}/rootwrap.d" do
  mode '0755'
end

%W[
  /var/lib/#{cookbook_name}/
  /var/lib/#{cookbook_name}/volumes/
].each do |path|
  directory path do
    owner cookbook_name
    group cookbook_name
    mode '0755'
  end
end

package 'mysql-client'
package 'libmysqlclient-dev' # for MySQL-python

# 만약 sql을 쓴다면 필요
python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

package 'libxslt1-dev' # lxml>=2.3 (from cinder==2014.1.4.dev27.g49db8c6)
package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->python-glanceclient>=0.9.0,!=0.14.0->cinder==2014.1.4.dev27.g49db8c6)
package 'libyaml-dev' # PyYAML>=3.1.0 (from oslo.messaging>=1.3.0->cinder==2014.1.4.dev27.g49db8c6)

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

template "/etc/sudoers.d/#{cookbook_name}_sudoers" do
  source "#{cookbook_name}_sudoers.erb"
  mode '0440'
end

bash "install #{cookbook_name} config" do
  code <<-EOH
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.conf /etc/#{cookbook_name}/rootwrap.conf
    cp #{source_path}/etc/#{cookbook_name}/policy.json /etc/#{cookbook_name}/policy.json
    cp #{source_path}/etc/#{cookbook_name}/api-paste.ini /etc/#{cookbook_name}/api-paste.ini
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/policy.json
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/api-paste.ini
EOH
  action :nothing
end

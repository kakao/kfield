source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
log "source_path : #{source_path}"

user cookbook_name do
  system true
  home "/var/lib/#{cookbook_name}"
  supports :manage_home => false
  shell '/bin/bash'
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

%W[
  /etc/#{cookbook_name}/
  /var/lib/#{cookbook_name}/
].each do |path|
  directory path do
    owner cookbook_name
    group cookbook_name
    mode '0755'
  end
end

package 'build-essential'
package 'libxslt1-dev'
package 'qemu-utils'
package 'mysql-client'
package 'python-pexpect'
package 'python-mysqldb'
package 'libmysqlclient-dev'

log node[:openstack][:github][:url]

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

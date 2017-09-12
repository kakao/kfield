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

%W[
  /var/lib/#{cookbook_name}/
  /var/lib/#{cookbook_name}/image-cache/
  /var/lib/#{cookbook_name}/images/
].each do |path|
  directory path do
    owner cookbook_name
    group cookbook_name
    mode '0755'
  end
end

if node.chef_environment != 'jenkins'
  package 'libyaml-dev' # PyYAML>=3.1.0 (from oslo.vmware>=0.2->glance==2014.1.4.dev7.g4b5cb74)
  package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->glance==2014.1.4.dev7.g4b5cb74)
end

# package "python-#{cookbook_name}"
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

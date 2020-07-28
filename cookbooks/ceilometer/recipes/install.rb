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

package 'libxslt1-dev' # lxml>=2.3 (from ceilometer==2014.1.4.dev9.g5793196)
package 'libyaml-dev' # PyYAML>=3.1.0 (from ceilometer==2014.1.4.dev9.g5793196)
package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->python-glanceclient>=0.9.0->ceilometer==2014.1.4.dev9.g5793196)

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

python_pip 'pymongo' do
  virtualenv node[:openstack][:install][:source][:path]
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
    cp #{source_path}/etc/#{cookbook_name}/api_paste.ini /etc/#{cookbook_name}/api_paste.ini
    cp #{source_path}/etc/#{cookbook_name}/pipeline.yaml /etc/#{cookbook_name}/pipeline.yaml
    cp #{source_path}/etc/#{cookbook_name}/policy.json /etc/#{cookbook_name}/policy.json
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.conf /etc/#{cookbook_name}/rootwrap.conf
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/api_paste.ini
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/pipeline.yaml
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/policy.json
EOH
  action :nothing
end

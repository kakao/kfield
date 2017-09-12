service = 'api'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

# 소스안에 config path가 ./etc/ ...
source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
bash "install #{cookbook_name}-#{service} config" do
  code <<-EOH
    cp #{source_path}/etc/glance-api-paste.ini /etc/#{cookbook_name}/glance-api-paste.ini
    cp #{source_path}/etc/policy.json /etc/#{cookbook_name}/policy.json
    cp #{source_path}/etc/schema-image.json /etc/#{cookbook_name}/schema-image.json
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/glance-api-paste.ini
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/policy.json
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/schema-image.json
EOH
  action :nothing
  subscribes :run, "git[#{source_path}]", :immediately
end

cookbook_file "/etc/#{cookbook_name}/glance-cache.conf" do
  source 'glance-cache.conf'
  owner cookbook_name
  group cookbook_name
end

cookbook_file "/etc/#{cookbook_name}/glance-scrubber.conf" do
  source 'glance-cache.conf'
  owner cookbook_name
  group cookbook_name
end

%W[
  /var/lib/#{cookbook_name}/image-cache/queue/
  /var/lib/#{cookbook_name}/image-cache/invalid/
  /var/lib/#{cookbook_name}/image-cache/incomplete/
].each do |path|
  directory path
end

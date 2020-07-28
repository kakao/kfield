package 'mysql-client'
package 'libmysqlclient-dev' # for MySQL-python

# 만약 sql을 쓴다면 필요
python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

service = 'api'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

directory "/etc/#{cookbook_name}" do
  owner cookbook_name
  group cookbook_name
  mode '0755'
end

directory "/etc/#{cookbook_name}/rootwrap.d" do
  mode '0755'
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
bash "install #{cookbook_name}-#{service} config" do
  code <<-EOH
    mkdir -p /etc/#{cookbook_name}/rootwrap.d
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/api-metadata.filters /etc/#{cookbook_name}/rootwrap.d/api-metadata.filters
    chmod 640 /etc/#{cookbook_name}/rootwrap.d/api-metadata.filters
EOH
  action :nothing
  subscribes :run, "git[#{source_path}]", :immediately
end

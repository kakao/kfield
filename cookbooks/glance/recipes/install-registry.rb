package 'mysql-client'
package 'libmysqlclient-dev' # for MySQL-python

# 만약 sql을 쓴다면 필요
python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

service = 'registry'

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
    cp #{source_path}/etc/glance-#{service}-paste.ini /etc/#{cookbook_name}/glance-#{service}-paste.ini
    chown #{cookbook_name}:#{cookbook_name} /etc/#{cookbook_name}/glance-#{service}-paste.ini
EOH
  action :nothing
  subscribes :run, "git[#{source_path}]", :immediately
end

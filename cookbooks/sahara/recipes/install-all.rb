sahara_enabled = node[:openstack][:enabled_service].include?('sahara')
return unless sahara_enabled

package 'mysql-client'
package 'libmysqlclient-dev' # for MySQL-python

# 만약 sql을 쓴다면 필요
python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

service = 'all'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

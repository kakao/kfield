
service = 'alarm-notifier'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

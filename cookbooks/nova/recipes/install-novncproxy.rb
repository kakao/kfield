
service = 'novncproxy'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/novnc"
git source_path do
  repository "#{node[:openstack][:github][:url]}/noVNC.git"
  revision 'v0.5'
  action :sync
  retries 5
  retry_delay 5
end

source_path_websockify = "#{node[:openstack][:install][:source][:path]}/src/websockify"
git source_path_websockify do
  repository "#{node[:openstack][:github][:url]}/websockify.git"
  revision 'v0.6.0'
  notifies :install, "python_pip[#{source_path_websockify}]", :immediately
  action :sync
  retries 5
  retry_delay 5
end

python_pip source_path_websockify do
  virtualenv node[:openstack][:install][:source][:path]
  options '-e'
  action :nothing
  retries 5
  retry_delay 5
end

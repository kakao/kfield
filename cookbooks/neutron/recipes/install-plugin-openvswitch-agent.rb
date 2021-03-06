
service = 'plugin-openvswitch-agent'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

template "/etc/init/#{cookbook_name}-ovs-cleanup.conf" do
  source "init-#{cookbook_name}-ovs-cleanup.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-ovs-cleanup" do
  to '/lib/init/upstart-job'
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
bash "install #{cookbook_name}-#{service} config" do
  code <<-EOH
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/openvswitch-plugin.filters /etc/#{cookbook_name}/rootwrap.d/openvswitch-plugin.filters
EOH
  action :nothing
  subscribes :run, "git[#{source_path}]", :immediately
end

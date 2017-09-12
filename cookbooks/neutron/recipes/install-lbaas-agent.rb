
extention = 'lbaas'
extention_service = cookbook_name + '-' + extention + '-agent'
extention_repo = cookbook_name + '-' + extention
extention_source_path = "#{node[:openstack][:install][:source][:path]}/src/#{extention_repo}"

template "/etc/init/#{extention_service}.conf" do
  source "init-#{extention_service}.conf.erb"
end

link "/etc/init.d/#{extention_service}" do
  to '/lib/init/upstart-job'
end

git extention_source_path do
  repository node[:openstack][:github][extention_repo.to_sym][:url]
  revision node[:openstack][:github][extention_repo.to_sym][:revision]
  action :sync
  notifies :install, "python_pip[#{extention_source_path}]", :immediately
  notifies :run, "bash[install #{extention_service} config]", :immediately
  retries 5
  retry_delay 5
end

python_pip extention_source_path do
  virtualenv node[:openstack][:install][:source][:path]
  options '-e'
  action :nothing
  retries 5
  retry_delay 5
end

bash "install #{extention_service} config" do
  code <<-EOH
    cp #{extention_source_path}/etc/neutron/rootwrap.d/lbaas-haproxy.filters /etc/#{cookbook_name}/rootwrap.d/lbaas-haproxy.filters
EOH
  action :nothing
end

package 'haproxy'

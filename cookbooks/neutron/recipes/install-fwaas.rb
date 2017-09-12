
extention = 'fwaas'
extention_repo = cookbook_name + '-' + extention
extention_source_path = "#{node[:openstack][:install][:source][:path]}/src/#{extention_repo}"

template '/etc/neutron/fwaas_driver.ini' do
  source 'fwaas_driver.ini.erb'
  group cookbook_name
end

git extention_source_path do
  repository node[:openstack][:github][extention_repo.to_sym][:url]
  revision node[:openstack][:github][extention_repo.to_sym][:revision]
  action :sync
  notifies :install, "python_pip[#{extention_source_path}]", :immediately
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

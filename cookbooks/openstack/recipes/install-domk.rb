
# domk
source_path = "#{node[:openstack][:install][:source][:path]}/src/domk"
git source_path do
  repository "#{node[:openstack][:github][:itfurl]}/domk"
  revision node[:openstack][:github][:domk][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
  notifies :run, 'bash[install python-domk]', :immediately
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

bash 'install python-domk' do
  code <<-EOH
    cp #{source_path}/etc/init.d/domk /etc/init.d/domk
    chmod 755 /etc/init.d/domk
    cp #{source_path}/etc/upstart/domk /etc/init/domk.conf
    sed -i 's|/usr/local/bin/|#{node[:openstack][:install][:source][:path]}/bin/|' /etc/init.d/domk
    sed -i 's|python /usr/local/bin/|python2.7 #{node[:openstack][:install][:source][:path]}/bin/|' /etc/init.d/domk
    sed -i 's|/usr/local/bin/|#{node[:openstack][:install][:source][:path]}/bin/|' /etc/init/domk.conf
EOH
  action :nothing
  notifies :run, 'execute[restart domk]'
end

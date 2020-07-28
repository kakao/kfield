
service = 'volume'

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
bash "install #{cookbook_name}-#{service} config" do
  code <<-EOH
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/volume.filters /etc/#{cookbook_name}/rootwrap.d/volume.filters
EOH
  action :nothing
  subscribes :run, "git[#{source_path}]", :immediately
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

package 'lvm2'
package 'tgt'
package 'qemu-utils'

directory '/etc/tgt/conf.d' do
  recursive true
end

cookbook_file '/etc/tgt/conf.d/cinder_tgt.conf' do
  source 'cinder_tgt.conf'
end

service 'tgt' do
  provider Chef::Provider::Service::Upstart
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
end

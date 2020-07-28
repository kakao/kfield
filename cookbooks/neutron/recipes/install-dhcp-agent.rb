
service = 'dhcp-agent'

# neutron-ns-metadata-proxy
# ImportError: No module named pysqlite2
python_pip 'pysqlite' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

template "/etc/cron.d/#{cookbook_name}-#{service}-netns-cleanup" do
  source "#{cookbook_name}-#{service}-netns-cleanup.erb"
end

template "/etc/#{cookbook_name}/rootwrap.d/dhcp.filters" do
  source 'dhcp.filters.erb'
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
bash "install #{cookbook_name}-#{service} config" do
  code <<-EOH
    mkdir -p /etc/#{cookbook_name}/rootwrap.d
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/route.filters /etc/#{cookbook_name}/rootwrap.d/route.filters
    chmod 640 /etc/#{cookbook_name}/rootwrap.d/route.filters
EOH
  action :nothing
  only_if { File::exists?("#{source_path}/etc/#{cookbook_name}/rootwrap.d/route.filters") }
  subscribes :run, "git[#{source_path}]", :immediately
end

package 'dnsmasq-base'
package 'dnsmasq-utils'

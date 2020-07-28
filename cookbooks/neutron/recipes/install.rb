source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"

# package "#{cookbook_name}-common"
user cookbook_name do
  system true
  home "/var/lib/#{cookbook_name}"
  supports :manage_home => false
  shell '/bin/false'
end

group cookbook_name do
  system true
  members cookbook_name
end

directory "/var/log/#{cookbook_name}/" do
  owner cookbook_name
  group 'adm'
  mode '0755'
end

directory "/var/lib/#{cookbook_name}/" do
  owner cookbook_name
  group cookbook_name
end

directory "/var/lib/#{cookbook_name}/" do
  group cookbook_name
  mode '0755'
end

directory "/etc/#{cookbook_name}/" do
  group cookbook_name
  mode '0755'
end

directory "/etc/#{cookbook_name}/plugins" do
  group cookbook_name
end

directory "/etc/#{cookbook_name}/rootwrap.d" do
  mode '0755'
end

package 'mysql-client'
package 'libmysqlclient-dev' # for MySQL-python
package 'ipset' # for security group

# 만약 sql을 쓴다면 필요
python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
end

# package "python-#{cookbook_name}"
git source_path do
  repository node[:openstack][:github][cookbook_name.to_sym][:url]
  revision node[:openstack][:github][cookbook_name.to_sym][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
  notifies :run, "bash[install #{cookbook_name} config]", :immediately
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

bash "install #{cookbook_name} config" do
  code <<-EOH
    cp #{source_path}/etc/rootwrap.conf /etc/#{cookbook_name}/rootwrap.conf
    cp #{source_path}/etc/vpn_agent.ini /etc/#{cookbook_name}/vpn_agent.ini
    cp #{source_path}/etc/api-paste.ini /etc/#{cookbook_name}/api-paste.ini
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/l3.filters /etc/#{cookbook_name}/rootwrap.d/l3.filters
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/iptables-firewall.filters /etc/#{cookbook_name}/rootwrap.d/iptables-firewall.filters
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/debug.filters /etc/#{cookbook_name}/rootwrap.d/debug.filters
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/vpnaas.filters /etc/#{cookbook_name}/rootwrap.d/vpnaas.filters
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/ipset-firewall.filters /etc/#{cookbook_name}/rootwrap.d/ipset-firewall.filters
    chown :#{cookbook_name} /etc/#{cookbook_name}/vpn_agent.ini
    chown :#{cookbook_name} /etc/#{cookbook_name}/policy.json
    chown :#{cookbook_name} /etc/#{cookbook_name}/api-paste.ini
EOH
  action :nothing
end

template "/etc/sudoers.d/#{cookbook_name}_sudoers" do
  source "#{cookbook_name}_sudoers.erb"
  mode '0440'
end

template "/etc/cron.d/#{cookbook_name}-l3-agent-netns-cleanup" do
  source "#{cookbook_name}-l3-agent-netns-cleanup.erb"
end

if node[:neutron][:lbaas][:enable] == true && node[:openstack][:release] == 'kilo'
  include_recipe "#{cookbook_name}::install-lbaas-agent"
end

if node[:neutron][:fwaas][:enable] == true && node[:openstack][:release] == 'kilo'
  include_recipe "#{cookbook_name}::install-fwaas"
end

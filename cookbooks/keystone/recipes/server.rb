::Chef::Recipe.send(:include, Kakao::Openstack)

if node[:openstack][:database][:use_managed_database]
  mysql_host = node[:openstack][:database][:hostname]
else
  mysql_node = node_by_role "openstack-mysql", {:wait=>true}
  fail 'mysql node not found from the role' unless mysql_node
  mysql_host = mysql_node[:fqdn]
end

fail 'mysql host not found' unless mysql_host

include_recipe "#{cookbook_name}::install"
include_recipe "#{cookbook_name}"

binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

keystone_password = dbpassword_for 'keystone'

directory '/etc/keystone/ssl' do
  user 'keystone'
  group 'keystone'
  mode 00755
end

directory '/etc/keystone/ssl/certs' do
  user 'keystone'
  group 'keystone'
  mode 00755
end

directory '/etc/keystone/ssl/private' do
  user 'keystone'
  group 'keystone'
  mode 00700
end

file '/etc/keystone/ssl/certs/serial' do
  content "02\n"
  user 'keystone'
  group 'keystone'
  mode 00664
end

cookbook_file '/etc/keystone/ssl/certs/signing_cert.pem' do
  source 'signing_cert.pem'
  user 'keystone'
  group 'keystone'
  mode 00664
end

cookbook_file '/etc/keystone/ssl/certs/ca.pem' do
  source 'ca.pem'
  user 'keystone'
  group 'keystone'
  mode 00444
end

cookbook_file '/etc/keystone/ssl/certs/cakey.pem' do
  source 'cakey.pem'
  user 'keystone'
  group 'keystone'
  mode 00400
end

cookbook_file '/etc/keystone/ssl/certs/req.pem' do
  source 'req.pem'
  user 'keystone'
  group 'keystone'
  mode 00664
end

cookbook_file '/etc/keystone/ssl/certs/01.pem' do
  source '01.pem'
  user 'keystone'
  group 'keystone'
  mode 00664
end

cookbook_file '/etc/keystone/ssl/private/signing_key.pem' do
  source 'signing_key.pem'
  user 'keystone'
  group 'keystone'
  mode 00400
end

directory "#{node[:keystone][:log_dir]}" do
  group "#{cookbook_name}"
  owner "#{cookbook_name}"
  recursive true
  mode '0755'
end

#
# apache settings
#
include_recipe 'apache2'
package 'libapache2-mod-wsgi'

apache_site 'default' do
  enable false
end

directory "#{node[:keystone][:cgi_path]}/keystone/" do
  recursive true
end

template "#{node[:keystone][:cgi_path]}/keystone/admin" do
  source 'admin-main.erb'
end

template "#{node[:keystone][:cgi_path]}/keystone/main" do
  source 'admin-main.erb'
end

template "#{node[:apache][:dir]}/sites-available/keystone.conf" do
  source 'keystone-apache.conf.erb'
  mode '0644'
  variables({
    :python_path => "python-path=#{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages",
  })
end

link "#{node[:apache][:dir]}/sites-enabled/keystone.conf" do
  to "#{node[:apache][:dir]}/sites-available/keystone.conf"
  only_if { File.exists?("#{node[:apache][:dir]}/sites-available/keystone.conf") }
end

memcache_node = nodes_by_role "memcached", {:wait=>true}
memcache_servers = memcache_node.sort{|x,y| x[:fqdn] <=> y[:fqdn]}.map{|x| "#{x[:fqdn]}:11211"}.join(',')

auth_addr = get_auth_address

sql_connection = "mysql://keystone:#{keystone_password}@#{mysql_host}/keystone"
rabbit_node = nodes_by_role "openstack-rabbitmq"

template '/etc/keystone/keystone.conf' do
  source 'keystone.conf.erb'
  mode '0644'
  variables({
    :connection => sql_connection,
    :memcache_servers => memcache_servers,
    :rabbit_node => rabbit_node,
    :auth_addr => auth_addr,
  })
  notifies :restart, 'service[apache2]', :immediately
end

execute 'Keystone: sleep' do
  command 'sleep 5s'
end

execute 'keystone sync' do
  command "#{binprefix}keystone-manage db_sync"
end

execute "change owner keystone log" do
  command "chown -R #{cookbook_name}:#{cookbook_name} #{node[:keystone][:log_dir]}"
  user 'root'
end

keystone_tenant 'admin' do
  auth_addr auth_addr
end

keystone_tenant 'service' do
  auth_addr auth_addr
end

node[:keystone][:additional_tenants].each do |tenant|
  keystone_tenant tenant do
    auth_addr auth_addr
  end
end

keystone_user 'admin' do
  password node[:openstack][:admin_passwd]
  email node[:keystone][:contact_email]
  auth_addr auth_addr
end

keystone_role 'admin' do
  auth_addr auth_addr
end

keystone_user_role 'admin' do
  tenant 'admin'
  role 'admin'
  auth_addr auth_addr
end

keystone_role 'Member' do
  auth_addr auth_addr
end

# create tenants/ users and assign roles
template '/root/keystone-clear.sh' do
  source 'keystone-clear.sh.erb'
  mode '0744'
end

logrotate_app 'keystone' do
  cookbook 'logrotate'
  path '/var/log/keystone/keystone.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 keystone keystone'
  postrotate 'restart keystone >/dev/null 2>&1 || true'
end

# Create endpoints / service
keystone_service 'keystone' do
  type 'identity'
  description 'OpenStack Identity Service'
  auth_addr auth_addr
end

regions = node[:openstack][:regions].nil? ? ['RegionOne'] : node[:openstack][:regions]
regions.each do | region |
  keystone_endpoint 'keystone' do
    region region
    public_url "#{auth_addr}:5000/v2.0"
    internal_url "#{auth_addr}:5000/v2.0"
    admin_url "#{auth_addr}:35357/v2.0"
    auth_addr auth_addr
  end
end

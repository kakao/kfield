::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe "#{cookbook_name}::install"

memcached_node = nodes_by_role "memcached"
unless node[:roles].include? "memcached"
  package 'memcached' do
    action 'remove'
  end
end

auth_host = get_auth_host
auth_protocol = get_auth_protocol

enable_lbaas = ! node_by_role('neutron-lbaas-agent', {:same_env=>false}).nil?
template '/etc/openstack-dashboard/local_settings.py' do
  source 'local_settings.py.erb'
  mode '0644'
  variables({
    :memcached_servers => memcached_node.empty? ? "'127.0.0.1:11211'" : \
      "['" + memcached_node.sort{|x,y| x[:fqdn] <=> y[:fqdn]}.map{|x| "#{x[:fqdn]}:11211"}.join("','") + "']",
    :auth_host => auth_host,
    :auth_protocol => auth_protocol,
    :enable_lbaas => enable_lbaas,
  })
  notifies :restart, "service[apache2]"
end

#
# apache settings
#
include_recipe 'apache2'
package 'libapache2-mod-wsgi'

apache_site 'default' do
  enable false
end

web_app 'horizon'

template "#{node[:apache][:dir]}/conf-available/openstack-dashboard.conf" do
  source 'openstack-dashboard.conf.erb'
  mode '0644'
  variables({
    :openstack_dashboard_path => "#{node[:horizon][:content_path]}/openstack_dashboard",
    :python_path => "python-path=#{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages",
  })
end

# enable dashboard conf
apache_conf 'openstack-dashboard'

# redirect to horizon service
template "#{node[:apache][:docroot_dir]}/index.html" do
  source 'index.html.erb'
  mode '0644'
end

template '/etc/logrotate.d/apache2' do
  source 'logrotate.apache2.erb'
  mode '0644'
end

directory '/var/log/apache2' do
  group 'adm'
  owner 'root'
  recursive true
  mode '0755'
end

include_recipe "#{cookbook_name}::_custom"

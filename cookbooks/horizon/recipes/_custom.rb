django_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
dashboard_share_path = "#{node[:horizon][:content_path]}/openstack_dashboard"
static_path = "#{dashboard_share_path}/static"

cookbook_file "#{static_path}/dashboard/img/custom_logo_splash.png" do
  source node[:horizon][:custom][:logo_splash]
  owner cookbook_name
  group cookbook_name
  mode '0644'
  only_if { node[:horizon][:custom][:logo_splash] }
end

cookbook_file "#{static_path}/dashboard/img/custom_logo_small.png" do
  source node[:horizon][:custom][:logo_small]
  owner cookbook_name
  group cookbook_name
  mode '0644'
  only_if { node[:horizon][:custom][:logo_small] }
end

cookbook_file "#{static_path}/dashboard/css/custom.css" do
  source node[:horizon][:custom][:css]
  owner cookbook_name
  group cookbook_name
  mode '0644'
  only_if { node[:horizon][:custom][:css] }
  notifies :run, 'bash[django_compress_source]'
end

template "#{dashboard_share_path}/templates/_stylesheets.html" do
  source '_stylesheets.html.erb'
  owner cookbook_name
  group cookbook_name
  mode '0644'
  notifies :run, 'bash[django_compress_source]'
end

bash 'django_compress_source' do
  action :nothing
  code <<-EOH
  #{node[:openstack][:install][:source][:path]}/bin/python #{node[:horizon][:content_path]}/manage.py collectstatic --noinput
  #{node[:openstack][:install][:source][:path]}/bin/python #{node[:horizon][:content_path]}/manage.py compress --force
  cd #{dashboard_share_path}
  #{node[:openstack][:install][:source][:path]}/bin/python #{node[:horizon][:content_path]}/manage.py compilemessages -l ko_KR
EOH
  cwd node[:horizon][:content_path]
  notifies :restart, 'service[apache2]', :immediately
end

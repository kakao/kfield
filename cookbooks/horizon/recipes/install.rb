source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"

user cookbook_name do
  system true
  home source_path
  supports :manage_home => false
  shell '/bin/false'
end

group cookbook_name do
  system true
  members cookbook_name
end

directory '/etc/openstack-dashboard' do
  owner cookbook_name
  group cookbook_name
  mode '0755'
end

directory '/var/lib/openstack-dashboard' do
  owner cookbook_name
  group cookbook_name
  mode '0700'
end

directory "#{node[:horizon][:content_path]}/openstack_dashboard/" do
  recursive true
end

directory "#{node[:horizon][:content_path]}/bin/less/" do
  recursive true
end

package 'libyaml-dev' # PyYAML>=3.1.0 (from python-heatclient>=0.2.3->horizon==2014.1.4.dev12.gfb429f4)
package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->python-glanceclient>=0.9.0->horizon==2014.1.4.dev12.gfb429f4)
package 'gettext' # use in scss

# package "python-django-#{cookbook_name}"
git source_path do
  repository node[:openstack][:github][cookbook_name.to_sym][:url]
  revision node[:openstack][:github][cookbook_name.to_sym][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
  notifies :run, "bash[reinstall openstack dashboard]", :immediately
  retries 5
  retry_delay 5
end

# horizon에서 glance-client를 사용하는데, 아래 의존성이 필요함
%w"python-dev libffi-dev libssl-dev".each do | p |
  package p
end

python_pip 'cryptography' do
  virtualenv node[:openstack][:install][:source][:path]
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

bash 'reinstall openstack dashboard' do
  action :nothing
  code <<-EOH
  rm -rf #{node[:horizon][:content_path]}/openstack_dashboard/
  mkdir -p #{node[:horizon][:content_path]}/openstack_dashboard/
  cp -R #{source_path}/openstack_dashboard/* #{node[:horizon][:content_path]}/openstack_dashboard/
  cp #{source_path}/manage.py #{node[:horizon][:content_path]}/
  cp #{source_path}/openstack_dashboard/settings.py #{node[:horizon][:content_path]}/
EOH
end

package 'python-lesscpy'

link "#{node[:horizon][:content_path]}/static" do
  to "#{node[:horizon][:content_path]}/openstack_dashboard/static"
end

link "#{node[:horizon][:content_path]}/bin/less/lessc" do
  to '/usr/bin/lesscpy'
end

link "#{node[:horizon][:content_path]}/openstack_dashboard/static/horizon" do
  to "#{source_path}/horizon/static/horizon"
end

execute 'chown openstack dashboard static' do
  command "chown -R #{cookbook_name}:#{cookbook_name} #{node[:horizon][:content_path]}/openstack_dashboard/static"
end

# django에서 compress를 사용하여 압축된 파일을 아래 디렉토리에 만드므로 www-data가 쓸 수 있는 권한이 필요함
directory "#{node[:horizon][:content_path]}/openstack_dashboard/static/dashboard/css" do
  owner cookbook_name
  group 'www-data'
  mode 0775
end

template "#{node[:horizon][:content_path]}/openstack_dashboard/wsgi/django.wsgi" do
  source 'django.wsgi.erb'
end

link "#{node[:horizon][:content_path]}/openstack_dashboard/local/local_settings.py" do
  to '/etc/openstack-dashboard/local_settings.py'
end

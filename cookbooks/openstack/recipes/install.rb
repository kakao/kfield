
package 'git'
package 'python-dev' # for pip install
package 'make'
package 'build-essential'
package 'libssl-dev'
package 'zlib1g-dev'
package 'libbz2-dev'
package 'libreadline-dev'
package 'libsqlite3-dev'
package 'wget'
package 'curl'
package 'llvm'

# create .netrc for github deploy apikey
template "#{ENV['HOME']}/.netrc" do
  source '.netrc.erb'
end

bash 'install pyenv' do
  environment 'https_proxy' => 'http://proxy.server.io:8080'
  code <<-EOH
    curl -sL https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer -o /tmp/pyenv-installer
    PYENV_ROOT=/opt/pyenv USE_HTTPS=true bash /tmp/pyenv-installer
  EOH
  not_if { File::exists?('/opt/pyenv/bin/pyenv') }
end

bash "install python #{node[:openstack][:install][:source][:python_version]}" do
  environment 'https_proxy' => 'http://proxy.server.io:8080'
  code <<-EOH
    PYENV_ROOT=/opt/pyenv PYTHON_CONFIGURE_OPTS="--enable-unicode=ucs4" /opt/pyenv/bin/pyenv install #{node[:openstack][:install][:source][:python_version]}
  EOH
  not_if { File::exists?("/opt/pyenv/versions/#{node[:openstack][:install][:source][:python_version]}/bin/python") }
end

bash "install python virtual env" do
  environment 'https_proxy' => 'http://proxy.server.io:8080'
  code <<-EOH
    /opt/pyenv/versions/#{node[:openstack][:install][:source][:python_version]}/bin/pip install virtualenv --proxy 'http://proxy.server.io:8080'
  EOH
  not_if { File::exists?("/opt/pyenv/versions/#{node[:openstack][:install][:source][:python_version]}/bin/virtualenv") }
end

bash "install python virtual env #{node[:openstack][:install][:source][:python_version]}" do
  code <<-EOH
    /opt/pyenv/versions/#{node[:openstack][:install][:source][:python_version]}/bin/virtualenv #{node[:openstack][:install][:source][:path]}
  EOH
  not_if { File::exists?(node[:openstack][:install][:source][:path]) }
end

directory "#{node[:openstack][:install][:source][:path]}/src"

# kakao openstack
source_path = "#{node[:openstack][:install][:source][:path]}/src/python-kakao-openstack"
git source_path do
  repository "#{node[:openstack][:github][:itfurl]}/python-kakao-openstack"
  revision node[:openstack][:github][:python_kakao_openstack][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
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

source_path_eventlet = "#{node[:openstack][:install][:source][:path]}/src/eventlet"
# https://github.com/eventlet/eventlet/issues/220
git source_path_eventlet do
  repository node[:openstack][:github][:eventlet][:url]
  revision node[:openstack][:github][:eventlet][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path_eventlet}]", :immediately
  retries 5
  retry_delay 5
end

python_pip source_path_eventlet do
  virtualenv node[:openstack][:install][:source][:path]
  options '-e'
  action :nothing
  retries 5
  retry_delay 5
end

# https://github.com/openstack/requirements/blob/master/tools/integration.sh
package 'libxml2-dev'
package 'libxslt1-dev'
package 'mysql-client'
package 'libmysqlclient-dev'
package 'libpq-dev'
package 'libnspr4-dev'
package 'pkg-config'
package 'libsqlite3-dev'
package 'libzmq-dev'
package 'libffi-dev'
package 'libldap2-dev'
package 'libsasl2-dev'
package 'ccache'

python_pip 'MySQL-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

python_pip 'wheel' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

# global requirement
source_path_global_requirement = "#{node[:openstack][:install][:source][:path]}/src/requirements"
git source_path_global_requirement do
  repository node[:openstack][:github][:requirements][:url]
  revision node[:openstack][:github][:requirements][:revision]
  action :sync
  notifies :run, "execute[install global-requirements]", :immediately
  retries 5
  retry_delay 5
end

option = '--proxy "" --use-wheel --no-index --find-links=http://ftp.wheelhouse.com/'
execute 'install global-requirements' do
  command "#{node[:openstack][:install][:source][:path]}/bin/pip install #{option} -r #{node[:openstack][:install][:source][:path]}/src/requirements/global-requirements.txt"
  action :nothing
  retries 5
  retry_delay 5
end

# python-glanceclient see CCC-483 tcp_keepalive
# - remote package version python-glanceclient
python_pip 'python-glanceclient' do
  virtualenv node[:openstack][:install][:source][:path]
  action :remove
  only_if "ls /opt/openstack/lib/python2.7/site-packages/python_glanceclient*"
end

source_path_glanceclient = "#{node[:openstack][:install][:source][:path]}/src/python-glanceclient"
git source_path_glanceclient do
  repository node[:openstack][:github][:glance_client][:url]
  revision node[:openstack][:github][:glance_client][:revision]
  action :sync
  notifies :install, "python_pip[#{ source_path_glanceclient }]", :immediately
  retries 5
  retry_delay 5
end

python_pip source_path_glanceclient do
  virtualenv node[:openstack][:install][:source][:path]
  options '-e'
  action :nothing
  retries 5
  retry_delay 5
end

execute "#{node[:openstack][:install][:source][:path]}/bin/openstack complete > /etc/bash_completion.d/openstack" do
  not_if { File::exists?("/etc/bash_completion.d/openstack") }
end

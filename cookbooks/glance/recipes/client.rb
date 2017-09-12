include_recipe 'keystone::client'

package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->python-glanceclient)

python_pip 'python-glanceclient' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

cookbook_file '/etc/bash_completion.d/glance' do
  source 'bash-completion'
end

# case node[:lsb][:codename]
# when 'precise'
#     pydir = '/usr/share/pyshared'
# when 'trusty'
#     pydir = '/usr/lib/python2.7/dist-packages'
# else
#     fail "not supported version #{node[:lsb][:codename]}"
# end

# # apply patches
# patches = []

# patches.each do | patch_file |
#     cookbook_file "#{Chef::Config[:file_cache_path]}/#{patch_file}" do
#         source patch_file
#         action :nothing
#         subscribes :create, "package[python-glanceclient]", :immediately
#     end

#     # apply patch
#     execute "apply #{patch_file}" do
#         command "patch -p1 -i #{Chef::Config[:file_cache_path]}/#{patch_file}"
#         cwd pydir
#         action :nothing
#         subscribes :run, "package[python-glanceclient]", :immediately
#     end
# end

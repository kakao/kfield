# local backing

package 'libxslt1-dev' # lxml>=2.3 (from nova==2014.1.4.dev45.g3dcdce3)
package 'libyaml-dev'# PyYAML>=3.1.0 (from oslo.messaging>=1.3.0->nova==2014.1.4.dev45.g3dcdce3)
package 'libffi-dev' # cryptography>=0.2.1 (from pyOpenSSL>=0.11->python-glanceclient>=0.9.0->nova==2014.1.4.dev45.g3dcdce3)

source_path = "#{node[:openstack][:install][:source][:path]}/src/nova"
git source_path do
  repository "#{node[:openstack][:github][:url]}/nova.git"
  revision node[:openstack][:github][:openstack][:revision]
  action :sync
  notifies :install, "python_pip[#{source_path}]", :immediately
  retries 5
  retry_delay 5
end

python_pip source_path do
  virtualenv node[:openstack][:install][:source][:path]
  options '-e'
  retries 5
  retry_delay 5
end

# @todo create cinder volumes
# pvcreate /dev/sdb
# vgcreate cinder-volumes /dev/sdb

execute 'create loopback' do
  command "truncate --size #{node[:cinder][:backing_file_size]} #{node[:cinder][:backing_file]}"
  creates node[:cinder][:backing_file]
end

execute 'losetup' do
  command "losetup #{node[:cinder][:loop_dev]} #{node[:cinder][:backing_file]}"
  not_if "losetup -a | grep #{node[:cinder][:backing_file]}"
end

execute 'pvcreate' do
  command "pvcreate #{node[:cinder][:loop_dev]}"
  not_if "pvscan | grep #{node[:cinder][:loop_dev]}"
end

execute 'vgscan' do
  command "vgcreate cinder-volumes #{node[:cinder][:loop_dev]}"
  not_if "vgscan | grep cinder-volumes"
end

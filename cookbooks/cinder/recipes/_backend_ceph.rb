include_recipe 'openstack::ceph-client'

# ceph는 이미 설정된 것을 사용하므로 아래는 어디선가 한 작업임..
# execute 'create volume pool' do
#     command 'ceph osd pool create volumes 128'
#     not_if 'rados lspools | grep volumes'
# end

# execute 'create volume keyring' do
#     command "ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images'"
#     not_if "ceph auth get-key client.volumes"
# end

# execute 'save volume keyring' do
#     command 'ceph auth get-or-create client.volumes > /etc/ceph/ceph.client.volumes.keyring'
#     creates '/etc/ceph/ceph.client.volumes.keyring'
# end

package 'python-ceph' do
  notifies :run, "bash[install ceph for cinder virtualenv]", :immediately
end
# ceph pypi is not ready.. https://github.com/ceph/ceph/tree/master/src/pybind
bash "install ceph for cinder virtualenv" do
  code <<-EOH
  cp /usr/lib/python2.7/dist-packages/rados.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/cephfs.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_rest_api.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/rbd.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_argparse.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
EOH
  action :nothing
  notifies :restart, 'service[cinder-volume]'
end
bash "install ceph for cinder virtualenv for check" do
  code <<-EOH
  cp /usr/lib/python2.7/dist-packages/rados.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/cephfs.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_rest_api.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/rbd.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_argparse.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
EOH
  not_if { File::exists?("#{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/rados.py") }
  notifies :restart, 'service[cinder-volume]'
end
package 'ceph-common'

template "/etc/ceph/ceph.client.#{node[:cinder][:rbd_user]}.keyring" do
  source 'ceph.keyring.erb'
  user 'cinder'
  group 'cinder'
  mode '0600'
  variables({
    :client => node[:cinder][:rbd_user],
    :auth_key => node[:cinder][:rbd_key],
  })
end

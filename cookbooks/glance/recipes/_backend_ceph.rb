include_recipe "openstack::ceph-client"

# ceph는 이미 설정된 것을 사용하므로 아래는 어디선가 한 작업임..
# execute 'create image pool' do
#     command 'ceph osd pool create images 128'
#     not_if 'rados lspools | grep images'
# end

# execute 'create images keyring' do
#     command "ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'"
#     not_if "ceph auth get-key client.images"
# end

# execute 'save images keyring' do
#     command 'ceph auth get-or-create client.images > /etc/ceph/ceph.client.images.keyring'
#     creates '/etc/ceph/ceph.client.images.keyring'
# end

package 'python-ceph' do
  notifies :run, "bash[install ceph for glance virtualenv]", :immediately
end
# ceph pypi is not ready.. https://github.com/ceph/ceph/tree/master/src/pybind
bash "install ceph for glance virtualenv" do
  code <<-EOH
  cp /usr/lib/python2.7/dist-packages/rados.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/cephfs.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_rest_api.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/rbd.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_argparse.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
EOH
  action :nothing
  notifies :restart, 'service[glance-api]'
end
bash "install ceph for glance virtualenv for check" do
  code <<-EOH
  cp /usr/lib/python2.7/dist-packages/rados.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/cephfs.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_rest_api.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/rbd.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
  cp /usr/lib/python2.7/dist-packages/ceph_argparse.py* #{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/
EOH
  not_if { File::exists?("#{node[:openstack][:install][:source][:path]}/lib/python2.7/site-packages/rados.py") }
  notifies :restart, 'service[glance-api]'
end
package 'ceph-common'

template "/etc/ceph/ceph.client.#{node[:glance][:rbd_user]}.keyring" do
    source 'ceph.keyring.erb'
    user 'glance'
    group 'glance'
    mode '0600'
    variables ({
        :client => node[:glance][:rbd_user],
        :auth_key => node[:glance][:rbd_key],
    })
end

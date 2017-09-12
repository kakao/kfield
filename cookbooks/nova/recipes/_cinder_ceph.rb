include_recipe 'openstack::ceph-client'

fail "node[:nova][:ceph_secret_uuid] required"if node[:nova][:ceph_secret_uuid].nil?
fail "node[:cinder][:rbd_key] required"if node[:cinder][:rbd_key].nil?
fail "node[:cinder][:rbd_user] required"if node[:cinder][:rbd_user].nil?

bash 'set secert value' do
  code <<-EOH
    cat > #{Chef::Config[:file_cache_path]}/secret.xml <<EOF
    <secret ephemeral='no' private='no'>
        <usage type='ceph'>
            <name>client.#{node[:cinder][:rbd_user]} secret</name>
        </usage>
        <uuid>#{node[:nova][:ceph_secret_uuid]}</uuid>
    </secret>
EOF
    virsh secret-define --file #{Chef::Config[:file_cache_path]}/secret.xml
    virsh secret-set-value --secret #{node[:nova][:ceph_secret_uuid]} --base64 '#{node[:cinder][:rbd_key]}'
EOH
  not_if "virsh secret-get-value #{node[:nova][:ceph_secret_uuid]}"
  notifies :restart, 'service[nova-compute]'
end

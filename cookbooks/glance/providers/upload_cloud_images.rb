action :create do
  ENV['OS_AUTH_URL'] = "#{new_resource.auth_addr}:5000/v3"
  ENV['OS_USERNAME'] = 'admin'
  ENV['OS_PROJECT_NAME'] = 'admin'
  ENV['OS_PASSWORD'] = node[:openstack][:admin_passwd]
  ENV['OS_IDENTITY_API_VERSION'] = '3'
  ENV['OS_CACERT'] = node[:openstack][:old_root_pem_path]
  ENV['OS_REGION_NAME'] = node[:openstack][:region_name]

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  package 'qemu-utils' if node[:glance][:backend] == 'ceph'

  node[:glance][:cloud_images].each do |image|
    disk_format = 'qcow2'

    cmd = "#{binprefix}openstack image create "
    cmd += "--public "
    cmd += "--disk-format #{disk_format} "
    cmd += "--container-format bare "
    cmd += "--copy-from '#{image[:url]}' "
    cmd += "'#{image[:name]}'"

    execute "create image: #{image[:name]}" do
      command cmd
      not_if "#{binprefix}openstack image list | grep ' | #{image[:name]} '"
    end
  end
  new_resource.updated_by_last_action(true)
end

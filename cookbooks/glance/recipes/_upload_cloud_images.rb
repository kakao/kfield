# install cloud images
# only supports qcow2 images

auth_addr = get_auth_address
binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

ENV['OS_TENANT_NAME'] = 'admin'
ENV['OS_USERNAME'] = 'admin'
ENV['OS_PASSWORD'] = node[:openstack][:admin_passwd]
ENV['OS_AUTH_URL'] = "#{auth_addr}:5000/v2.0/"
ENV['OS_CACERT'] = node[:openstack][:old_root_pem_path]

package 'qemu-utils' if node[:glance][:backend] == 'ceph'

node[:glance][:cloud_images].each do |image|
  break if File.exists?("#{Chef::Config[:file_cache_path]}/skip_glance_image_upload")

  disk_format = 'qcow2'

  # @todo havana에서는 stdin에서 입력을 받을 수 있게 되어있을 거임.. 그걸로...
  execute "create image: #{image[:name]}" do
    command "#{binprefix}glance image-create --is-public true --disk-format #{disk_format} --container-format bare --name '#{image[:name]}' --copy-from '#{image[:url]}'"
    not_if "#{binprefix}glance image-list | grep ' | #{image[:name]} '"
  end
end

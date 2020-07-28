
action :create do

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  bash "create #{new_resource.name} endpoint" do
    code <<-EOH
    #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 service create \
      --name '#{new_resource.name}' \
      --description '#{new_resource.description}' \
      --enable \
      '#{new_resource.type}'
    EOH
    not_if "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 service show #{new_resource.name}"
  end
  new_resource.updated_by_last_action(true)
end

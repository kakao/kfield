
action :create do

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  execute "create role: #{new_resource.name}" do
    command "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 role create '#{new_resource.name}'"
    not_if "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 role show '#{new_resource.name}'"
  end
  new_resource.updated_by_last_action(true)
end

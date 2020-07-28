
action :add do

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  execute "user role add: #{new_resource.user} #{new_resource.tenant} #{new_resource.role}" do
    command "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 role add --user='#{new_resource.user}' --project='#{new_resource.tenant}' '#{new_resource.role}'"
    not_if "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 role list --user='#{new_resource.user}' --project='#{new_resource.tenant}' | grep ' #{new_resource.role} '"
  end
  new_resource.updated_by_last_action(true)
end

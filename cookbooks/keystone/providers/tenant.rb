
action :create do
  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  cmd = "#{binprefix}openstack "
  cmd += "--os-url #{new_resource.auth_addr}:5000/v3 "
  cmd += "--os-token #{node[:openstack][:admin_token]} "
  cmd += "--os-identity-api-version 3 "
  cmd += "--os-cacert #{node[:openstack][:old_root_pem_path]} "
  cmd += "project create "
  cmd += "--domain='default' "
  cmd += "--description='#{new_resource.description}' "
  cmd += "--enable "
  cmd += "#{new_resource.name}"

  execute "create tenant #{new_resource.name}" do
    command cmd
    not_if "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 project show #{new_resource.name}"
  end
  new_resource.updated_by_last_action(true)
end

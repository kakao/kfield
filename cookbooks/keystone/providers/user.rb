
action :create do
  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  cmd = "#{binprefix}openstack "
  cmd += "--os-url #{new_resource.auth_addr}:5000/v3 "
  cmd += "--os-token #{node[:openstack][:admin_token]} "
  cmd += "--os-identity-api-version 3 "
  cmd += "--os-cacert #{node[:openstack][:old_root_pem_path]} "
  cmd += "user create "
  cmd += "--domain default "
  cmd += "--password='#{new_resource.password}' "
  cmd += "--email=#{new_resource.email} " if new_resource.email

  tenant_id = new_resource.tenant_id
  if new_resource.tenant
    tenant_id = `#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 project show '#{new_resource.tenant}' | awk '/ id /{print $4}'`.strip
    raise RuntimeError, "tenant #{tenant_id} not found" if !tenant_id
  end

  cmd += "--project='#{tenant_id}' " if tenant_id
  cmd += "--enable "
  cmd += "#{new_resource.username} "

  execute "create user: #{new_resource.username}" do
    command cmd
    not_if "#{binprefix}openstack --os-url #{new_resource.auth_addr}:5000/v3 --os-cacert #{node[:openstack][:old_root_pem_path]} --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 user show '#{new_resource.username}'"
  end
  new_resource.updated_by_last_action(true)
end


action :create do

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  domain_id = `#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 domain show '#{new_resource.domain_name}' | awk '/ id /{print $4}'`.strip
  raise RuntimeError, "domain #{domain_id} not found" if !domain_id

  if new_resource.domain_admin_password
    # create user for domain
    domain_admin_create_cmd = "#{binprefix}openstack "
    domain_admin_create_cmd += "--os-url #{new_resource.auth_addr}:5000/v3 "
    domain_admin_create_cmd += "--os-token #{node[:openstack][:admin_token]} "
    domain_admin_create_cmd += "--os-identity-api-version 3 "
    domain_admin_create_cmd += "--os-cacert #{node[:openstack][:old_root_pem_path]} "
    domain_admin_create_cmd += "user create #{new_resource.domain_admin_name} "
    domain_admin_create_cmd += "--password #{new_resource.domain_admin_password} "
    domain_admin_create_cmd += "--domain #{domain_id} "
    domain_admin_create_cmd += "--description 'Manages users and projects created by #{new_resource.domain_name}' "

    execute "create domain [#{new_resource.domain_name}] admin user : #{new_resource.domain_admin_name}" do
      command domain_admin_create_cmd
      not_if "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 user show '#{new_resource.domain_admin_name}'"
    end

    # set admin role to domain_admin_user
    domain_admin_role_add_cmd = "#{binprefix}openstack "
    domain_admin_role_add_cmd += "--os-url #{new_resource.auth_addr}:5000/v3 "
    domain_admin_role_add_cmd += "--os-token #{node[:openstack][:admin_token]} "
    domain_admin_role_add_cmd += "--os-identity-api-version 3 "
    domain_admin_role_add_cmd += "--os-cacert #{node[:openstack][:old_root_pem_path]} "
    domain_admin_role_add_cmd += "role add admin "
    domain_admin_role_add_cmd += "--user #{new_resource.domain_admin_name} "
    domain_admin_role_add_cmd += "--domain #{domain_id} "

    execute "add admin role to domain_admin_user : #{new_resource.domain_admin_name}" do
      command domain_admin_role_add_cmd
    end
  end
  new_resource.updated_by_last_action(true)
end

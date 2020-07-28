
action :create do

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  domain_create_cmd = "#{binprefix}openstack "
  domain_create_cmd += "--os-url #{new_resource.auth_addr}:5000/v3 "
  domain_create_cmd += "--os-token #{node[:openstack][:admin_token]} "
  domain_create_cmd += "--os-identity-api-version 3 "
  domain_create_cmd += "--os-cacert #{node[:openstack][:old_root_pem_path]} "
  domain_create_cmd += "domain create "
  domain_create_cmd += "--description 'Owns users and projects created by #{new_resource.domain_name}' "
  domain_create_cmd += "#{new_resource.domain_name} "

  execute "create domain: #{new_resource.domain_name}" do
    command domain_create_cmd
    not_if "#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 domain show '#{new_resource.domain_name}'"
  end
  new_resource.updated_by_last_action(true)
end

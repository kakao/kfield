
action :create do

  binprefix = "#{node[:openstack][:install][:source][:path]}/bin/"

  region_opt = "#{new_resource.region}"

  bash "create #{new_resource.name} endpoint for region #{new_resource.region}" do
    code <<-EOH
      endpoints=`#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint list | grep -w '#{new_resource.name} ' | grep -c #{new_resource.region}`

      function create_endpoint() {
    #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint create --region #{region_opt} --enable #{new_resource.name} public '#{new_resource.public_url}';
    #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint create --region #{region_opt} --enable #{new_resource.name} admin '#{new_resource.admin_url}';
    #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint create --region #{region_opt} --enable #{new_resource.name} internal '#{new_resource.internal_url}';
      }

      if [ "$endpoints" == "0" ]; then
          create_endpoint
      else
          # update endpoint
          public_endpoint=`#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint list | grep -w '#{new_resource.name} ' | grep #{new_resource.region} | grep public`
          admin_endpoint=`#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint list | grep -w '#{new_resource.name} ' | grep #{new_resource.region} | grep admin`
          internal_endpoint=`#{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint list | grep -w '#{new_resource.name} ' | grep #{new_resource.region} | grep internal`

          public_endpoint_id=`echo $public_endpoint | awk '{print $2}'`
          public_url=`echo $public_endpoint | awk '{print $14}'`

          admin_endpoint_id=`echo $admin_endpoint | awk '{print $2}'`
          admin_url=`echo $admin_endpoint | awk '{print $14}'`

          internal_endpoint_id=`echo $internal_endpoint | awk '{print $2}'`
          internal_url=`echo $internal_endpoint | awk '{print $14}'`

          if [ "$public_url" != "#{new_resource.public_url}" -o "$internal_url" != "#{new_resource.internal_url}" -o \
             "$admin_url" != "#{new_resource.admin_url}" ]; then
              #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint delete $public_endpoint_id
              #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint delete $admin_endpoint_id
              #{binprefix}openstack --os-cacert #{node[:openstack][:old_root_pem_path]} --os-url #{new_resource.auth_addr}:5000/v3 --os-token #{node[:openstack][:admin_token]} --os-identity-api-version 3 endpoint delete $internal_endpoint_id
              create_endpoint
          fi
      fi
    EOH
  end
  new_resource.updated_by_last_action(true)
end

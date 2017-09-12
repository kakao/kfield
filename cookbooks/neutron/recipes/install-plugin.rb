
if node[:neutron][:plugin] == 'ml2'
  source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
  bash "install #{cookbook_name}-ml2 config" do
    code <<-EOH
      mkdir -p /etc/#{cookbook_name}/plugins/ml2
      chmod 755 /etc/#{cookbook_name}/plugins/ml2
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_ofa.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_ofa.ini
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_arista.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_arista.ini
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_mlnx.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_mlnx.ini
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_brocade.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_brocade.ini
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_cisco.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_cisco.ini
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_odl.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_odl.ini
      cp #{source_path}/etc/#{cookbook_name}/plugins/ml2/ml2_conf_ncs.ini /etc/#{cookbook_name}/plugins/ml2/ml2_conf_ncs.ini
  EOH
    action :nothing
    subscribes :run, "git[#{source_path}]", :immediately
  end
end

directory "/etc/#{cookbook_name}/plugins/#{node[:neutron][:plugin_agent]}" do
  mode '0755'
end

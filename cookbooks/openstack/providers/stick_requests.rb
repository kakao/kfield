action :update do
  fail 'this LWRP only applies to juno release' unless node[:openstack][:release] == 'juno'

  path = new_resource.path

  bash 'stick python-requests version to 2.4.1' do
    code <<-EOH
      find #{ path }/lib/python2.7/site-packages -maxdepth 2 -name METADATA | xargs -L1 sed -i -E 's|requests \\([<>=\\.,0-9\\!]+\\)|requests (==2.4.1)|'
    EOH
  end

  new_resource.updated_by_last_action(true)
end

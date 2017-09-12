def _get_loadbalancer_host(role, same_env = true)
  q = ''
  q += "chef_environment:#{node.chef_environment} AND " if same_env
  q += 'roles:openstack-api-loadbalancer'

  loadbalancer = search(:node, q)
  loadbalancer.each do |lb|
    next unless lb[:haproxy][:listeners][:listen].key?(role)

    lb[:haproxy][:listeners][:listen][role].each do |line|
      return lb[:haproxy][:api_fqdn] if line.include?('server')
    end
  end

  nil
end

def _get_host(role, same_env = true)
  q = ''
  q += "chef_environment:#{node.chef_environment} AND " if same_env
  q += "roles:#{role}"

  host = search(:node, q)
  return host.sort { |x, y| x[:fqdn] <=> y[:fqdn] }[0][:fqdn] unless host.empty?

  return node[:fqdn] if node[:roles].include? role
  nil
end

def get_auth_host
  host = _get_loadbalancer_host 'keystone', false
  return node[:openstack][:auth_server] if node[:openstack][:auth_server] && host == node[:openstack][:api_server]
  return host if host

  # loadbalancer가 없으면 다른 호스트를 찾는다.
  host = _get_host('openstack-keystone', false)
  return host if host

  node[:openstack][:auth_server]
end

def get_api_host
  host = _get_loadbalancer_host 'glance-api', true
  return host if host

  host = _get_host('glance-api')
  return host if host

  node[:openstack][:api_server]
end

def get_auth_protocol
  # region은 다른 chef server search가 안되서 미리 고정해둠.
  return 'https' unless (node[:openstack][:regions].nil? and node[:openstack][:region_name].nil?)

  host = _get_loadbalancer_host 'keystone', false
  return 'http' unless host

  protocol = node[:openstack][:use_ssl] ? 'https' : 'http'

  protocol
end

def get_api_protocol
  host = _get_loadbalancer_host 'glance-api', true
  return 'http' unless host

  protocol = node[:openstack][:use_ssl] ? 'https' : 'http'

  protocol
end

def get_auth_address
  host = get_auth_host
  protocol = get_auth_protocol

  "#{protocol}://#{host}"
end

def get_api_address
  host = get_api_host
  protocol = get_api_protocol

  "#{protocol}://#{host}"
end

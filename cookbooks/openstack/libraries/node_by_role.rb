# have to think about this library,
# need to change this to service discovery based one
# until we find a way to use service discovery
# leave this.

module Kakao
  module Openstack
    def nodes_by_role(role, args={})
      defaults = {:same_env=>true, :wait=>false}
      options = defaults.merge(args)

      same_env = options[:same_env] || defaults[:same_env]
      wait = options[:wait] || defaults[:wait]

      wait_role role, same_env if wait

      q = ''
      q += "chef_environment:#{node.chef_environment} AND " if same_env
      q += "roles:#{role}"

      result, _, _ = Chef::Search::Query.new.search(:node, q)
      presult = result.map { |r| r.name }

      if result.to_a.empty?
        if  node['roles'].include?(role)
          return [node]
        end
        return []
      else
        return result
      end
    end

    def node_by_role(role, args={})
      Chef::Log.info "search for role '#{role}'"
      defaults = {:same_env=>true, :wait=>false}
      options = defaults.merge(args)

      same_env = options[:same_env] || defaults[:same_env]
      wait = options[:wait] || defaults[:wait]

      wait_role role, same_env if wait
      result = nodes_by_role(role, {:same_env=>same_env})

      if result.empty?
        Chef::Log.info "Cannot find node for role '#{role}'"
        return nil
      end
      return result[0]
    end

    # 필요한 role이 setting 되기 기다리기 위한 간단한 node setup waiting...
    # knife-lastrun plugin을 이용해서 성공적으로 chef-client가 실행되면
    # node[:lastrun]에 정보가 설정되고 이를 이용해서 필요한 노드가 설저되기까지 기다림
    def wait_role(role, same_env=true)
      while true do
        n = node_by_role(role, {:same_env=>same_env})
        if n == node
          break if not n.nil?
        else
          break if not n.nil? and n.has_key? :lastrun and n[:lastrun][:status] == 'success'
        end
         puts "Wait for role #{role}..."
        Chef::Log.info "Wait for role #{role}..."
        sleep Random.rand(60)
      end
    end

    def get_database_host
      if node[:openstack][:database][:use_managed_database]
        node[:openstack][:database][:hostname]
      else
        mysql_node = node_by_role "openstack-mysql", {:wait=>true}
        fail 'mysql node not found' unless mysql_node

        return mysql_node.is_a?(String) ? mysql_node : mysql_node[:fqdn]
      end
    end

    def dbpassword_for(user)
      # 개발환경에서는 고정 암호... 나머지는 environment에 주어진 암호를 사용한다.
      if check_environment_production
        password = node[:openstack][:database][:password][user]
      else
        password = "<#{user}-password>"
      end

      fail "database password for #{user} required! #{password}" unless password

      password
    end
  end
end

Chef::Resource.send(:include, Kakao::Openstack)

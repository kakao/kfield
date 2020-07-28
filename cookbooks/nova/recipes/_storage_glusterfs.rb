# glusterfs를 사용하는 것은
# - nova-compute에 gluster-server를 설치하고
# - /var/lib/nova/instances 에 마운트 한다.
::Chef::Recipe.send(:include, Kakao::Openstack)

package 'glusterfs-server'

# peer probe
compute_nodes = nodes_by_role "nova-compute"
compute_nodes.select{ |x| x[:fqdn] != node[:fqdn] }.each do |compute_node|
  execute "gluster probe #{compute_node[:fqdn]}" do
    command "gluster peer probe #{compute_node[:fqdn]}"
    not_if "gluster peer status | grep #{compute_node[:fqdn]}"
  end
end

gluster_path = '/gluster'
directory "#{gluster_path}/instances" do
  recursive true
end

replica = 3

# gluster volume create
# 볼륨이 없고, replica -1 만큼 노드가 있는 경우에 실행하지요..
peers = compute_nodes.map { |x| "#{x[:fqdn]}:#{gluster_path}/instances" }.join(' ')
execute 'volume create' do
  command "gluster volume create instances replica 3 #{peers}"
  only_if "! gluster volume info instances &&
           test $(gluster peer status | awk '/Number/{print $4}') -ge #{replica - 1}" 
end

# gluster volume start
execute 'volume start' do
  command 'gluster volume start instances'
  only_if "gluster volume info instances | grep '^Status: Created'"
end

# add peer brick
compute_nodes = nodes_by_role "nova-compute"
compute_nodes.select{ |x| x[:fqdn] != node[:fqdn] }.each do |compute_node|
  execute "gluster probe #{compute_node[:fqdn]}" do
    command "gluster volume add-brick instances #{compute_node[:fqdn]}:#{gluster_path}/instances"
    not_if "gluster volume info instances | grep #{compute_node[:fqdn]}"
  end
end

# mount instance directory
mount "#{node[:nova][:state_path]}/instances" do
  fstype 'glusterfs'
  device 'localhost:instances'
  only_if "gluster volume info instances | grep '^Status: Started'"
end

directory "#{node[:nova][:state_path]}/instances" do
  owner 'nova'
  group 'nova'
end

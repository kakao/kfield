::Chef::Recipe.send(:include, Kakao::Openstack)

include_recipe 'openstack::ceph-client'

# mount instance directory
mon_node = nodes_by_role "ceph-mon"
dev = mon_node.map{|x| "#{x[:ipaddress]}:6789" }.join(',')

begin
  # @note /etc/fstab에 넣으면 자동으로 마운트가 될 것 같으나, ceph 서비스가 뜨기 전에 마운트가 일어나서
  # 시스템 부팅 과정에서 마운트가 안된다. 따라서 /etc/fstab에 넣지 않고 chef에 의해서 자동으로 마운트
  # 되도록 놔둔다.

  # @todo /var/lib/nova/instance를 mount 해서 쓰는 ceph, gluster의 경우 만일 mount하기 전에 이 호스트에
  # 인스턴스가 할당되는 경우가 있을 수 있으므로, 마운트 되기 전에는 nova-compute 서비스를 죽여야 하지 않을까?
  unless mon_node.empty?
    mount "#{node[:nova][:state_path]}/instances" do
      device "#{dev}:/"
      fstype 'ceph'
      options "name=admin,secret=#{IO.popen('ceph auth get-key client.admin').read.strip}"
      action :mount
      only_if "ceph auth get-key client.admin"
    end
  end
rescue Errno::ENOENT => e
  # compiletime에는 ceph가 설치되지 않은 상태이다. 이 경우 컴파일 타임에 options, only_if에
  # 실행하는 ceph가 Exception이 발생하므로 exception handling을 했다.
  Chef::Log.info(e.inspect)
end

include_recipe "#{cookbook_name}::common"
include_recipe 'ceilometer::compute-agent'

fail "hypervisor #{node[:nova][:hypervisor]} not supported" \
  unless node[:nova][:hypervisor] == 'kvm'

# nova compute
package 'pm-utils'          # https://bugs.launchpad.net/ubuntu/+source/libvirt/+bug/994476
package 'genisoimage'   # for config-drive

include_recipe "#{cookbook_name}::install-compute"
include_recipe "#{cookbook_name}::_storage_#{node[:nova][:storage_backend]}"
include_recipe "#{cookbook_name}::_cinder_#{node[:cinder][:backend]}" unless node[:cinder][:backend].nil?

unless check_environment_jenkins
  execute 'enable vhost_net' do
    command 'modprobe vhost_net'
    not_if 'lsmod | grep vhost_net'
  end
end

package 'python-guestfs'
execute 'relax guestfs restriction' do
  command 'chmod 0644 /boot/vmlinuz*'
end

template '/etc/libvirt/qemu.conf' do
  source 'qemu.conf.erb'
  notifies :restart, 'service[libvirt-bin]'
  variables({
    :dynamic_ownership => 1,
  })
end

template '/etc/libvirt/libvirtd.conf' do
  source 'libvirtd.conf.erb'
  variables({
    # for live migration
    :listen_tls => 0,
    :listen_tcp => 1,
    :auth_tcp => 'none',
  })
  notifies :restart, 'service[libvirt-bin]'
  only_if { node[:nova][:use_live_migration] }
end

template '/etc/default/libvirt-bin' do
  source 'libvirt-bin.erb'
  variables({
    # for live migration
    :libvirtd_opts => '-d -l'
  })
  notifies :restart, 'service[libvirt-bin]'
  only_if { node[:nova][:use_live_migration] }
end

service 'libvirt-bin' do
  supports :status => :true, :restart => :true, :reload => :true
  action [:enable, :start]
end

execute 'delete default bridge' do
  command 'virsh net-destroy default && virsh net-undefine default'
  only_if 'virsh net-list | grep default'
end

template '/etc/nova/nova-compute.conf' do
  source 'nova-compute.conf.erb'
  owner 'nova'
  group 'nova'
  mode '0600'
  notifies :restart, 'service[nova-compute]'
end

service 'nova-compute' do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

# for migration
# migration은 대상 호스트에 ssh + rsync의 작업이 필요하므로 private를 설정한다.
if node[:nova][:use_migration]
  directory "#{node[:nova][:state_path]}/.ssh" do
    owner 'nova'
    group 'nova'
  end
  user 'nova' do
    action :modify
    shell '/bin/bash'
  end
  cookbook_file "#{node[:nova][:state_path]}/.ssh/id_rsa" do
    source 'id_rsa'
    owner 'nova'
    group 'nova'
    mode 0600
  end
  cookbook_file "#{node[:nova][:state_path]}/.ssh/id_rsa.pub" do
    source 'id_rsa.pub'
    owner 'nova'
    group 'nova'
  end
  cookbook_file "#{node[:nova][:state_path]}/.ssh/authorized_keys" do
    source 'id_rsa.pub'
    owner 'nova'
    group 'nova'
  end
  # ssh로 다른 compute 로그인해 들어갈 때 host key checking을 하지 않도록
  # 이러면서 이전에 있었던 host fingerprint 등록 과정이 필요없음
  cookbook_file "#{node[:nova][:state_path]}/.ssh/config" do
    source 'config'
    owner 'nova'
    group 'nova'
  end
  # 이제는 필요없음
  cookbook_file "#{node[:nova][:state_path]}/.ssh/known_hosts" do
    action :delete
  end
end

# 쓸데없이 cpu 만 잡아먹고있음
service 'open-iscsi' do
  supports :status => :true, :restart => :true, :reload => :true
  action [:disable, :stop]
end

package 'open-iscsi' do
  action :purge
end

# @todo recipe를 include하는 작업이 끝나면 삭제한다.
# - ceilometer-compute-agele role 삭제
if node.roles.include?('ceilometer-compute-agent')
  node.run_list.delete('role[ceilometer-compute-agent]')
  node.save
end

# change scheduler to noop
node[:block_device].select { |k, v| /^[sv]d[a-z]/ =~ k }.each do |device, value|
  sysfs "change scheduler to #{node[:nova][:blockdev_scheduler]} for device #{device}" do
    action :set
    variable "block/#{device}/queue/scheduler"
    value node[:nova][:blockdev_scheduler]
  end
end

logrotate_app 'nova-compute' do
  cookbook 'logrotate'
  path '/var/log/nova/nova-compute.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 nova nova'
  postrotate 'restart nova-compute >/dev/null 2>&1 || true'
end

include_recipe "#{cookbook_name}::_tuning"
include_recipe "#{cookbook_name}::_swap"

# install kvm utility packages
package 'virt-top'
package 'htop'
package 'nethogs'
package 'ethtool'
package 'tshark'

bash "vtysh terminal setting" do
  user "root"
  code <<-EOS
   echo "export VTYSH_PAGER=more" >> /etc/bash.bashrc  
  EOS
  not_if "grep -q  'export VTYSH_PAGER=more' /etc/bash.bashrc"
end

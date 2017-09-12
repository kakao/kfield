::Chef::Recipe.send(:include, Kakao::Openstack)

package 'python-pip'

include_recipe "#{cookbook_name}::install"

package 'ubuntu-cloud-keyring' do
  only_if { node[:lsb][:release] == '12.04' }
end

fail "Not supported release #{node[:lsb][:release]}" unless %w{12.04 14.04}.include?(node[:lsb][:release])

# for ubuntu 12.04 only
# qemu-kvm을 ubuntu 12.04에서도 2.0.0+dfsg-2ubuntu1.11~cloud0를 써야
# venom 을 막을 수 있음.. (http://venom.crowdstrike.com/)
# juno 버전이지만 icehouse qemu를 가져와도 dependency는 맞음..(12.04는 juno버전이 없음..)
apt_repository 'openstack-updates' do
  uri node[:openstack][:cloud_archive_url]
  distribution "#{node[:lsb][:codename]}-updates/icehouse"
  components ['main']
  only_if { node[:lsb][:release] == '12.04' }
end

template '/etc/apt/sources.list' do
  source "sources.list.erb"
  notifies :run, 'execute[apt-get update]', :immediately
end

cookbook_file node[:openstack][:old_root_pem_path] do
  source 'old_root.pem'
end

# create openrc
begin
  template '/root/openrc' do
    source 'openrc.erb'
    variables({
      :auth_addr => get_auth_address,
    })
  end
rescue NameError => e
  # get_auth_host는 없을 수 있음..
end

# create openrc_v3
begin
  template '/root/openrc_v3' do
    source 'openrc_v3.erb'
    variables({
      :auth_addr => get_auth_address,
    })
  end
rescue NameError => e
  # get_auth_host는 없을 수 있음..
end

directory '/root/bin'
template '/root/bin/os-clear.sh' do
  source 'os-clear.sh.erb'
  mode 00755
end

template '/root/bin/os-dbdump.sh' do
  source 'os-dbdump.sh.erb'
  action node.roles.include?('openstack-mysql') ? :create : :delete
  mode 00755
end

cookbook_file '/root/bin/os-vm-create.sh' do
  source 'os-vm-create.sh'
  action node.roles.include?('openstack-control') ? :create : :delete
  mode 00755
end

file '/root/bin/os-vm-create.rc.provider-net' do
  action :delete
end

cookbook_file '/root/bin/os-mig.sh' do
  source 'os-mig.sh'
  action node.roles.include?('openstack-control') ? :create : :delete
  mode 00755
end

template '/root/bin/os-service.sh' do
  source 'os-service.sh.erb'
  mode 00755
end

# @note 나중에 지워도 됨...
file '/root/bin/os-restart.sh' do
  action :delete
  only_if { File.exists?('/root/bin/os-service.sh') }
end

cookbook_file '/root/bin/os-reinstall.sh' do
  source 'os-reinstall.sh'
  mode 00755
end

# migration scripts
# @remove quantum --> neutron migration(havana) 삭제, 나중에 지우시오..
directory '/root/bin/migration' do
  action :delete
  recursive true
end

template '/etc/vim/vimrc.local' do
  source 'vimrc.local.erb'
  mode 0644
end

include_recipe 'openstack::_figlet'

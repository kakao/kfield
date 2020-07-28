
return if check_environment_jenkins

sysctl_param 'vm.swappiness' do
  value node[:nova][:tunable][:swappiness]
end

sysfs 'turn on KSM' do
  action :set
  variable 'kernel/mm/ksm/run'
  value "1"
end

# Large segment offload
package 'ethtool'

bash 'turn on LSO' do
  code <<-EOC
  ethtool -K #{node[:neutron][:guest_iface]} rx on
  ethtool -K #{node[:neutron][:guest_iface]} ufo on
  ethtool -K #{node[:neutron][:guest_iface]} gso on
  ethtool -K #{node[:neutron][:guest_iface]} gro on
EOC
  only_if "ethtool #{node[:neutron][:guest_iface]}"
end

cookbook_file '/etc/sysctl.d/60-nfconntrack.conf' do
  source '60-nfconntrack.conf'
  notifies :run, 'execute[service procps start]'
end

execute 'service procps start' do
  action :nothing
end

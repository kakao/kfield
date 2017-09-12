
# Package: nova-compute
# Version: 1:2014.1.3-0ubuntu1~cloud0
# Depends: nova-common (= 1:2014.1.3-0ubuntu1~cloud0), nova-compute-kvm | nova-compute-hypervisor, upstart-job, python
service = 'compute'

template "/etc/init/#{cookbook_name}-#{service}.conf" do
  source "init-#{cookbook_name}-#{service}.conf.erb"
end

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

directory "/etc/#{cookbook_name}" do
  owner cookbook_name
  group cookbook_name
  mode '0755'
end

directory "/etc/#{cookbook_name}/rootwrap.d" do
  mode '0755'
end

source_path = "#{node[:openstack][:install][:source][:path]}/src/#{cookbook_name}"
bash "install #{cookbook_name}-#{service} config" do
  code <<-EOH
    mkdir -p /etc/#{cookbook_name}/rootwrap.d
    cp #{source_path}/etc/#{cookbook_name}/rootwrap.d/compute.filters /etc/#{cookbook_name}/rootwrap.d/compute.filters
    chmod 640 /etc/#{cookbook_name}/rootwrap.d/compute.filters
EOH
  action :nothing
  subscribes :run, "git[#{source_path}]", :immediately
end
# Package: nova-compute - end

# Package: nova-compute-kvm
# Version: 1:2014.1.3-0ubuntu1~cloud0
# Depends: nova-compute-libvirt (= 1:2014.1.3-0ubuntu1~cloud0), qemu-system (>= 1.3.0) | kvm
package 'qemu-system'

# nova conf 설정
# Package: nova-compute-kvm - end

# Package: nova-compute-libvirt
# Version: 1:2014.1.3-0ubuntu1~cloud0
# Depends: adduser, ebtables, genisoimage, iptables, kpartx, libvirt-bin, nova-compute (= 1:2014.1.3-0ubuntu1~cloud0), parted, python-libvirt, qemu-utils, vlan
%w[
  ebtables
  genisoimage
  iptables
  kpartx
  libvirt-bin
  parted
  qemu-utils
  vlan
].each do |p|
  package p
end

# libvirt-python을 소스로 인스톨 하기 위해서 필요
package 'libvirt-dev'

python_pip 'libvirt-python' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

group 'libvirtd' do
  members cookbook_name
end
# Package: nova-compute-libvirt - end

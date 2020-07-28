name 'neutron-dhcp-agent'
description 'OpenStack neutron dhcp agent service'
run_list(
     'role[openstack-base]',
     'role[neutron-agent]',
     'recipe[neutron::dhcp-agent]',
)
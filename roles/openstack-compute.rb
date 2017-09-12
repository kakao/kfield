name 'openstack-compute'
description 'OpenStack compute node'
run_list(
     'role[nova-compute]',
     'role[neutron-dhcp-agent]',
     'role[neutron-metadata-agent]'
)
name 'openstack-network'
description 'OpenStack network node'
run_list(
     'role[neutron-metadata-agent]',
     'role[neutron-dhcp-agent]',
     'role[neutron-l3-agent]',
     'role[neutron-lbaas-agent]',
)
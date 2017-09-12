name 'openstack-all-in-one'
description 'OpenStack all-in-one node'
run_list(
    'role[openstack-control]',
    'role[openstack-network]',
    'role[openstack-compute]',
)

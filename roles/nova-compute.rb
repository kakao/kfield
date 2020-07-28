name 'nova-compute'
description 'OpenStack compute node'
run_list(
    'role[openstack-base]',
    'role[neutron-agent]',
    'recipe[nova::compute]'
)
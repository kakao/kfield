name 'ceilometer-collector'
description 'OpenStack ceilometer collector service'
run_list(
    'role[openstack-base]',
    'recipe[ceilometer::collector]'
)

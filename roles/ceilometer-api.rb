name 'ceilometer-api'
description 'OpenStack ceilometer api service'
run_list(
    'role[openstack-base]',
    'recipe[ceilometer::api]'
)

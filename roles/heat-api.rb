name 'heat-api'
description 'OpenStack heat api service'
run_list(
    'role[openstack-base]',
    'recipe[heat::api]'
)

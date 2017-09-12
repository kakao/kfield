name 'heat-engine'
description 'OpenStack heat engine service'
run_list(
    'role[openstack-base]',
    'recipe[heat::engine]'
)

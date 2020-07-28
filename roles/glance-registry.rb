name 'glance-registry'
description 'OpenStack glance-registry service'
run_list(
    'role[openstack-base]',
    'recipe[glance::registry]',
)

name 'glance-api'
description 'OpenStack glance api service'
run_list(
    'role[openstack-base]',
    'recipe[glance::api]',
)

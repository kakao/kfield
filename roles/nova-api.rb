name 'nova-api'
description 'OpenStack nova-api service'
run_list(
    'role[openstack-base]',
    'recipe[nova::api]',
)

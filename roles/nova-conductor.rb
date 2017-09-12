name 'nova-conductor'
description 'OpenStack nova-conductor service'
run_list(
    'role[openstack-base]',
    'recipe[nova::conductor]',
)

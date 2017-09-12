name 'nova-consoleauth'
description 'OpenStack nova-consoleauth service'
run_list(
    'role[openstack-base]',
    'recipe[nova::consoleauth]',
)

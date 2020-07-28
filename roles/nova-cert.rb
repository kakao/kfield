name 'nova-cert'
description 'OpenStack nova-cert service'
run_list(
    'role[openstack-base]',
    'recipe[nova::cert]',
)

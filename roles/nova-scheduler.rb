name 'nova-scheduler'
description 'OpenStack nova-scheduler service'
run_list(
    'role[openstack-base]',
    'recipe[nova::scheduler]',
)

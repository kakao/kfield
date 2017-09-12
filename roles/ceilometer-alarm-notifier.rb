name 'ceilometer-alarm-notifier'
description 'OpenStack ceilometer alarm-notifier service'
run_list(
    'role[openstack-base]',
    'recipe[ceilometer::alarm-notifier]'
)

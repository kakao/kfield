name 'ceilometer-agent-central'
description 'OpenStack ceilometer agent-central service'
run_list(
    'role[openstack-base]',
    'recipe[ceilometer::agent-central]'
)

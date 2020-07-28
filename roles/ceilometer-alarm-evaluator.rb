name 'ceilometer-alarm-evaluator'
description 'OpenStack ceilometer alarm-evaluator service'
run_list(
    'role[openstack-base]',
    'recipe[ceilometer::alarm-evaluator]'
)

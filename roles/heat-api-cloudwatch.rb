name 'heat-api-cloudwatch'
description 'OpenStack heat api-cloudwatch service'
run_list(
    'role[openstack-base]',
    'recipe[heat::api-cloudwatch]'
)

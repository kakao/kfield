name 'heat-api-cfn'
description 'OpenStack heat api-cfn service'
run_list(
    'role[openstack-base]',
    'recipe[heat::api-cfn]'
)

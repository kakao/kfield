name 'trove-api'
description 'OpenStack trove-api service'
run_list(
    'role[openstack-base]',
    'recipe[trove::api]',
)


name 'trove-conductor'
description 'OpenStack trove-conductor service'
run_list(
    'role[openstack-base]',
    'recipe[trove::conductor]',
)


name 'trove-taskmanager'
description 'OpenStack trove-taskmanager service'
run_list(
    'role[openstack-base]',
    'recipe[trove::taskmanager]',
)


name 'horizon-server'
description 'OpenStack horizon service'
run_list(
    'role[openstack-base]',
    'recipe[horizon]',
)

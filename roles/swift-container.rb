name 'swift-container'
description 'OpenStack swift container service'
run_list(
    'role[openstack-base]',
    'recipe[swift::container-server]'
)

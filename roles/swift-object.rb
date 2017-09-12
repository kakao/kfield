name 'swift-object'
description 'OpenStack swift object service'
run_list(
    'role[openstack-base]',
    'recipe[swift::object-server]'
)

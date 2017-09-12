name 'swift-saio'
description 'OpenStack swift proxy account container object service'
run_list(
    'role[openstack-base]',
    'role[swift-proxy]',
    'role[swift-account]',
    'role[swift-container]',
    'role[swift-object]'
)

name 'swift-account'
description 'OpenStack swift account service'
run_list(
    'role[openstack-base]',
    'recipe[swift::account-server]'
)

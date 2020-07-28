name 'openstack-control-shared'
description 'OpenStack control shared node'
run_list(
     'role[openstack-keystone]',
     'role[horizon-server]',
)
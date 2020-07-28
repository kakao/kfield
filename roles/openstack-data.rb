name 'openstack-data'
description 'OpenStack data store'
run_list(
     'role[openstack-base]',
     'role[openstack-rabbitmq]',
     'role[openstack-mysql]',
)

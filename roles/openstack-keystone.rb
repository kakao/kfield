name 'openstack-keystone'
description 'OpenStack keystone service'
run_list(
     "role[openstack-base]",
     "recipe[keystone::server]",
)

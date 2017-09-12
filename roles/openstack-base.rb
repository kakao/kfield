name 'openstack-base'
description 'OpenStack base role'
run_list(
     "role[base]",
     "recipe[openstack::default]",
)

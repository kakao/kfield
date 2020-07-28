name 'neutron-server'
description 'OpenStack neutron server'
run_list(
     'role[openstack-base]',
     'recipe[neutron::server]',
)

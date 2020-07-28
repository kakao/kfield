name 'neutron-agent'
description 'OpenStack neutron agent'
run_list(
     'role[openstack-base]',
     'recipe[neutron::agent]',
)

name 'neutron-lbaas-agent'
description 'OpenStack neutron lbaas agent service'
run_list(
     'role[openstack-base]',
     'recipe[neutron::lbaas-agent]',
)

name 'neutron-l3-agent'
description 'OpenStack neutron l3 agent service'
run_list(
     'role[openstack-base]',
     'role[neutron-agent]',
     'recipe[neutron::l3-agent]',
)
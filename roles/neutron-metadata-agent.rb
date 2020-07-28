name 'neutron-metadata-agent'
description 'OpenStack neutron metadata agent service'
run_list(
     'role[openstack-base]',
     'role[neutron-agent]',
     'recipe[neutron::metadata-agent]',
)
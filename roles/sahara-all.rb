name 'sahara-all'
description 'OpenStack sahara-all service'
run_list(
    'role[openstack-base]',
    'recipe[sahara::all]'
)

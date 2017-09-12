name 'cinder-volume'
description 'OpenStack cinder volume service'
run_list(
    'role[openstack-base]',
    'recipe[cinder::volume]'
)
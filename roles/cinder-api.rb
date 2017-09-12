name 'cinder-api'
description 'OpenStack cinder api service'
run_list(
    'role[openstack-base]',
    'recipe[cinder::api]'
)
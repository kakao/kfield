name 'cinder-scheduler'
description 'OpenStack cinder scheduler service'
run_list(
    'role[openstack-base]',
    'recipe[cinder::scheduler]'
)
name 'nova-novncproxy'
description 'OpenStack nova-novncproxy service'
run_list(
    'role[openstack-base]',
    'recipe[nova::novncproxy]',
)

name 'glance-server'
description 'OpenStack glance service'
run_list(
    'role[glance-api]',
    'role[glance-registry]',
)

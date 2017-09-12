name 'memcached'
description 'memcached services'
run_list(
    'role[base]',
    'recipe[openstack::memcached]'
)

override_attributes(
  'memcached' => {
    'memory' => 1024
  }
)

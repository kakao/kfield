name 'ceilometer-datastore'
description 'OpenStack ceilometer datastore service'
run_list(
    'recipe[build-essential]',
    'recipe[ceilometer::datastore]'
)

override_attributes(
    'build-essential' => {
        'compile_time' => true,
    },
)

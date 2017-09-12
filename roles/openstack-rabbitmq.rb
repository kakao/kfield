name 'openstack-rabbitmq'
description 'OpenStack rabbitmq'
run_list(
     'role[base]',
     'recipe[openstack::rabbitmq]',
)

override_attributes(
    :rabbitmq => {
        :address => '0.0.0.0',
        :port => 5672,
        :use_distro_version => true,
        :max_file_descriptors => '102400',
        :open_file_limit => '102400',
        :default_user => 'rabbit',
        :default_pass => '__rabbit_passwd__',
        :default_vhost => '/',
    },
)

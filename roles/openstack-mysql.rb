name 'openstack-mysql'
description 'OpenStack MySQL Database'
run_list(
     'role[base]',
     'recipe[mysqld]',
     'recipe[openstack::mysql]',
)

override_attributes(
     :mysqld => {
          :root_password => '<root-password>',
          'my.cnf' => {
               'mysqld' => {
                    'bind-address' => '0.0.0.0',
                    'character-set-server' => 'utf8',
                    'collation-server' => 'utf8_general_ci',
                    'max_connections' => '500',
               },
          },
     },
)

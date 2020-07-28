name "global"
description "OpenStack Inhouse Global environment"
cookbook_versions

default_attributes(
)

override_attributes(
    :chef_client => {
        :server_url => "https://your_chef_server/",
    },
    :openstack => {
        :regions => ['default'],
        :api_server => 'your_keystone_public_auth',
        :auth_server => 'your_keystone_public_auth',
        :redirect_url_from => 'your_source_horizon',
        :redirect_url_to => 'your_horizon/',
        :lb => {
            :pem_file => 'azoro.com.pem',
        },
        :database => {
            :hostname => 'ccc-busanone.mydb.your.com',
            :password => {
                :keystone => 'c9_aijb_uGjz1JHOC3DB',
            },
        },
        :enabled_service => %w(),
        # nova-novncproxy에 사용될 url.. 일반 사용자에게 접근이 가능해야함.
        :dashboard_server => 'your_horizon/',
    },
    :horizon => {
        :help_url => 'https://your_guide/',
        :secret_key => 'b5a8ef07d766eb7aa16fb4cc73c5aa9e',
        :disable_zones => ['DB_Zone00', 'Pool', 'nova'],
        :disable_zones_except_tenant => ['751fe244a1d546fcb9c2abdbbd0e1cb5', '549f096869324619af22213afe20e841', '395282b46b83451785299f0e2fa84a3a'],
    },
)

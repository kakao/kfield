name 'openstack-api-loadbalancer'
description 'OpenStack API Load Balancer'
run_list(
    'role[base]',
    'recipe[openstack::api-lb]',
)

override_attributes(
    :haproxy => {
        :enable_default_http => false,
        # haproxy를 1.5dev로 직접 컴파일해서 설치하는 이유는...
        # haproxy에서 ssl offload 기능을 사용하는데, 이 기능이 1.5devXX 부터 들어갔기 때문임.
        :install_method => 'source',
        :default_options => ["dontlognull", "redispatch"],
        :source => {
            :version => '1.5.3',
            :url => 'http://ftp.yoursite.com//binaries/haproxy/haproxy-1.5.3.tar.gz',
            :checksum => '0dad3680e0c3592a165781e1cc9b0d5cc88d8eaa8ebf59719c9bd62bb9c1cd9e',
            :use_openssl => true,
        },
    },
)

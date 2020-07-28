name 'swift-proxy'
description 'OpenStack swift proxy service'
run_list(
    'role[openstack-base]',
    'recipe[swift::reverse-proxy]',
    'recipe[swift::proxy-server]'
)

override_attributes(
    :haproxy => {
        :enable_default_http => false,
        # haproxy를 1.5dev로 직접 컴파일해서 설치하는 이유는...
        # haproxy에서 ssl offload 기능을 사용하는데, 이 기능이 1.5devXX 부터 들어갔기 때문임.
        :install_method => 'source',
        :default_options => ["dontlognull", "redispatch"],
        :source => {
            :version => '1.5-dev19',
            :url => 'http://ftp.yoursite.com/binaries/haproxy/haproxy-1.5-dev19.tar.gz',
            :checksum => 'cb411f3dae1309d2ad848681bc7af1c4c60f102993bb2c22d5d4fd9f5d53d30f',
            :use_openssl => true,
        },
    },
)

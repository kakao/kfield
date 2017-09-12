name             'neutron'
maintainer       'ccc'
maintainer_email 'ccc@daumkakao.com'
license          'All rights reserved'
description      'Installs/Configures neutron'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.10.21'
supports 'ubuntu', '>= 12.04'

depends 'base'
depends 'openstack'
depends 'keystone'
depends 'logrotate'
depends 'sysctl'

name             'ceilometer'
maintainer       'ccc'
maintainer_email 'ccc@kakaocorp.com'
license          'All rights reserved'
description      'Installs/Configures ceilometer'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.10.21'
supports 'ubuntu', '>= 12.04'

depends 'base'
depends 'keystone'
depends 'sysfs'
depends 'mongodb3'
depends 'logrotate'

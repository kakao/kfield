name             'base'
maintainer       'ccc'
maintainer_email 'ccc@kakaocorp.com'
license          'All rights reserved'
description      'The base role'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.10.21'

depends 'rsyslog'
depends 'openstack'
depends 'chef_handler'

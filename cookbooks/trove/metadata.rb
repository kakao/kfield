name             'trove'
maintainer       'ccc'
maintainer_email 'ccc@kakaocorp.com'
license          'All rights reserved'
description      'Installs/Configures trove'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.10.21'

depends 'base'
depends 'openstack'
depends 'keystone'
depends 'nova'
depends 'glance'

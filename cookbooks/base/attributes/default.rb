default[:base][:talk_handler][:room] = '503' # talkroom
default[:base][:packages] = %w()

default['apt']['key_proxy'] = 'http://proxy.server.io:8080'

default[:base][:pypi][:index_url] = 'http://ftp.daumkakao.com/pypi/simple/'
default[:base][:pypi][:proxy] = ''

default[:base][:rubygems][:gem_sources] = ['http://ftp.daumkakao.com/rubygems/']
default[:base][:rubygems][:gem_disable_default] = true
default[:base][:rubygems][:chef_gem_sources] = ['http://ftp.daumkakao.com/rubygems/']
default[:base][:rubygems][:chef_gem_disable_default] = true

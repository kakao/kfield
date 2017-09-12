default[:horizon][:help_url] = 'http://docs.openstack.org/'
default[:horizon][:timezone] = 'Asia/Seoul'

default[:horizon][:processes] = 3
default[:horizon][:threads] = 10

default[:horizon][:password_autocomplete] = 'off'
# cat /dev/urandom | LC_CTYPE=C tr -dc A-Za-z0-9_ | head -c 16 # 아니면 # uuidgen -r
default[:horizon][:secret_key] = '<horizon-secret-key>'

# customizing
default[:horizon][:custom][:site_branding] = nil
default[:horizon][:custom][:logo_spash] = nil
default[:horizon][:custom][:logo_small] = nil
default[:horizon][:custom][:css] = nil

default[:horizon][:disable_zones] = %w{}
default[:horizon][:additional_zones] = %w{}
default[:horizon][:disable_zones_except_tenant] = %w{}

default[:horizon][:content_path] = '/usr/share/openstack-dashboard'

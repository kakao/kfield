default[:keystone][:use_syslog] = true
default[:keystone][:logfile] = 'keystone.log'
default[:keystone][:log_dir] = '/var/log/keystone'
default[:keystone][:conf_dir] = '/etc/keystone'

# apache
default[:keystone][:processes] = 3
default[:keystone][:threads] = 10
default[:keystone][:cgi_path] = '/var/www/cgi-bin'
default[:keystone][:apache_log_dir] = '/var/log/apache2'

# sql or ldap_auth
default[:keystone][:identity_driver] = 'inhouse_sso'

# sql or memcache
default[:keystone][:token_driver] = 'memcache'
default[:keystone][:token_format] = 'UUID'

# 추가로 생성할 tenants 지정, ldap_auth를 사용할 경우 기본 tenant를 여기다 넣으세요
default[:keystone][:additional_tenants] = []

# Identity custom settings
default[:keystone][:identity][:auto_create_user] = true
default[:keystone][:identity][:email_postfix] = '@yourdomain.com'
# TODO: default_project는 이제 없어질 기능이다.
# 또는 user_id로 default tenant를 만든다.
default[:keystone][:identity][:default_project] = 'demo'
default[:keystone][:identity][:member_role] = 'Member'
# ldap/ inhouse_sso 인증에서 제외할 사용자 설정, 아래에 지정된 계정은 keystone에 유지한다.
default[:keystone][:identity][:system_users] = 'admin,nova,quantum,neutron,cinder,glance,heat,ceilometer,swift,docker-registry,heat_domain_admin,sahara'
default[:keystone][:contact_email] = 'ccc@kakaocorp.com'

## ldap_auth settings
default[:keystone][:ldap_auth][:url] = 'ldap://localhost'
default[:keystone][:ldap_auth][:ldap_postfix] = '@mycompany.com'

# nil to number of CPUs
default[:keystone][:admin_workers] = nil
default[:keystone][:public_workers] = nil

# cache
default[:keystone][:cache][:backend] = 'dogpile.cache.memcached'
default[:keystone][:cache][:enabled] = true

case node[:keystone][:identity_driver]
when 'sql'
    default[:keystone][:identity_driver_class] = 'keystone.identity.backends.sql.Identity'
when 'inhouse_sso'
    default[:keystone][:identity_driver_class] = 'keystone.identity.backends.inhouse_sso.Identity'
    default[:keystone][:inhouse_sso][:access_key] = 'sso_key'
when 'ldap_auth'
    default[:keystone][:identity_driver_class] = 'keystone.identity.backends.ldap_auth.Identity'
else
    fail "invalid keystone driver #{node[:keystone][:identity_driver]}"
end

case node[:keystone][:token_driver]
when 'sql'
    default[:keystone][:token_driver_class] = 'keystone.token.persistence.backends.sql.Token'
when 'memcache'
    default[:keystone][:token_driver_class] = 'keystone.token.persistence.backends.memcache.Token'
else
    fail "invalid keystone token driver #{node[:keystone][:token_driver]}"
end

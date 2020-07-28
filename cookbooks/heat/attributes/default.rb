default[:heat][:use_syslog] = true
default[:heat][:log_dir] = '/var/log/heat'

default[:heat][:workers][:api] = 5
default[:heat][:workers][:api_cloudwatch] = 5
default[:heat][:workers][:api_cfn] = 5
default[:heat][:workers][:engine] = 5

# 기본값은 heat.common.heat_keystoneclient.KeystoneClientV3 이지만 V3를 사용하면
# keystone domain 관련 설정이 필요하다.
#   stack_user_domain, stack_domain_admin, stack_domain_admin_password
# 아직 도메인을 사용하지 않는 v2.0을 사용한다.
default[:heat][:keystone_backend] = 'heat.common.heat_keystoneclient.KeystoneClientV3'

# 지정하지 않으면 http protocol로 redirect를 해버린다.
default[:heat][:secure_proxy_ssl_header] = 'X-Forwarded-Proto'

# 지정하지 않으면 ec2-user로 user가 생성된다.
default[:heat][:instance_user] = 'root'
# 지정하지 않으면 cfntools가 http protocol을 사용하여 heat-api-cfn으로 접근. https로 변경
default[:heat][:instance_connection_is_secure] = true


# keystone domain 설정
default[:heat][:stack_user_domain_id] = nil
default[:heat][:stack_user_domain_name] = 'heat'
default[:heat][:stack_domain_admin] = 'heat_domain_admin'
default[:heat][:stack_domain_admin_password] = '__heat_passwd__'

# heat 인증방식 trusts or password
default[:heat][:deferred_auth_method] = 'trusts'

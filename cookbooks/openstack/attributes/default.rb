default[:openstack][:debug][:global] = false
default[:openstack][:debug][:ceilometer] = node[:openstack][:debug][:global]
default[:openstack][:debug][:cinder] = node[:openstack][:debug][:global]
default[:openstack][:debug][:glance] = node[:openstack][:debug][:global]
default[:openstack][:debug][:heat] = node[:openstack][:debug][:global]
default[:openstack][:debug][:horizon] = node[:openstack][:debug][:global]
default[:openstack][:debug][:keystone] = node[:openstack][:debug][:global]
default[:openstack][:debug][:neutron] = node[:openstack][:debug][:global]
default[:openstack][:debug][:nova] = node[:openstack][:debug][:global]
default[:openstack][:debug][:sahara] = node[:openstack][:debug][:global]
default[:openstack][:debug][:trove] = node[:openstack][:debug][:global]

default[:openstack][:verbose] = true

default[:openstack][:release] = 'kilo'

default[:openstack][:no_proxy] = 'localhost,127.0.0.1'

#
# default[:openstack][:cloud_archive_url] = 'http://ubuntu-cloud.archive.canonical.com/ubuntu'
# 내부 Cloud Archive Mirror 지정
default[:openstack][:cloud_archive_url] = 'http://ubuntu-cloud-archive.yoursite.com/ubuntu'
default[:openstack][:bad_agents] = [
  'hdr(Acunetix-Product) -m reg -i ^WVS',
  'hdr(User-Agent) -m reg (ZmEu|paros|nikto|dirbuster|sqlmap|openvas|w3af|Morfeus|JCE|Zollard)',
]

default[:openstack][:enabled_service] = []

# true면 DB팀에서 관리하는 데이터베이스를 사용한다.
#    :password를 미리 지정된 것으로 지정한다.
# false면 openstack::mysql-master recipe에서 자동으로 만들어 내는 암호를 사용하고
#    그 설정을 search로 찾아서 자동으로 설정하므로 아래 :password 설정은 필요없다.
default[:openstack][:database][:use_managed_database] = true

default[:openstack][:lb][:pem_file] = 'your.com.pem'
default[:openstack][:use_ssl] = true
default[:openstack][:redirect_url_from] = ''
default[:openstack][:redirect_url_to] = ''
default[:openstack][:regions] = nil
default[:openstack][:region_name] = nil

default[:openstack][:api_server] = nil
default[:openstack][:auth_server] = nil

default[:openstack][:identity_api_version] = '3'

default[:openstack][:install][:source][:python_version] = '2.7.9'
default[:openstack][:install][:source][:path] = '/opt/openstack'

default[:openstack][:github][:domain] = 'github.your.com'
default[:openstack][:github][:apikey] = 'a4b9c6d2c1361a74c9765cacdd27b625381084c1'
default[:openstack][:github][:url] = "https://#{node[:openstack][:github][:domain]}/openstack"
default[:openstack][:github][:itfurl] = "https://#{node[:openstack][:github][:domain]}/ITF"
default[:openstack][:github][:openstack][:revision] = 'kakao/kilo'
default[:openstack][:github][:requirements][:url] = "#{node[:openstack][:github][:url]}/requirements.git"
default[:openstack][:github][:requirements][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:eventlet][:url] = "#{node[:openstack][:github][:url]}/eventlet.git"
default[:openstack][:github][:eventlet][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:ceilometer][:url] = "#{node[:openstack][:github][:url]}/ceilometer.git"
default[:openstack][:github][:ceilometer][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:cinder][:url] = "#{node[:openstack][:github][:url]}/cinder.git"
default[:openstack][:github][:cinder][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:glance][:url] = "#{node[:openstack][:github][:url]}/glance.git"
default[:openstack][:github][:glance][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:glance_client][:url] = "#{node[:openstack][:github][:url]}/python-glanceclient.git"
default[:openstack][:github][:glance_client][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:heat][:url] = "#{node[:openstack][:github][:url]}/heat.git"
default[:openstack][:github][:heat][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:horizon][:url] = "#{node[:openstack][:github][:url]}/horizon.git"
default[:openstack][:github][:horizon][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:keystone][:url] = "#{node[:openstack][:github][:url]}/keystone.git"
default[:openstack][:github][:keystone][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:neutron][:url] = "#{node[:openstack][:github][:url]}/neutron.git"
default[:openstack][:github][:neutron][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:'neutron-lbaas'][:url] = "#{node[:openstack][:github][:url]}/neutron-lbaas.git"
default[:openstack][:github][:'neutron-lbaas'][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:'neutron-fwaas'][:url] = "#{node[:openstack][:github][:url]}/neutron-fwaas.git"
default[:openstack][:github][:'neutron-fwaas'][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:nova][:url] = "#{node[:openstack][:github][:url]}/nova.git"
default[:openstack][:github][:nova][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:swift][:url] = "#{node[:openstack][:github][:url]}/swift.git"
default[:openstack][:github][:swift][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:trove][:url] = "#{node[:openstack][:github][:url]}/trove.git"
default[:openstack][:github][:trove][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:sahara][:url] = "#{node[:openstack][:github][:url]}/sahara.git"
default[:openstack][:github][:sahara][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:python_kakao_openstack][:revision] = node[:openstack][:github][:openstack][:revision]
default[:openstack][:github][:domk][:revision] = '0.6.0'

default['openstack']['mysql']['client']['packages'] = 'mysql-client', 'libmysqlclient-dev'

default[:openstack][:notification_driver] = ['messaging']

default[:openstack][:admin_token] = '__admin_token__'
default[:openstack][:admin_passwd] = '__admin_passwd__'
default[:openstack][:service_passwd] = '__service_passwd__'

default[:openstack][:domk][:debug] = true
default[:openstack][:domk][:logfile] = '/var/log/domk.log'
default[:openstack][:domk][:polling_interval] = 10
default[:openstack][:domk][:services] = %w(domain azro)

default[:openstack][:domk][:domain][:auth_url] = 'https://your_keystone_public_auth:5000/v2.0'
default[:openstack][:domk][:domain][:ttl] = 300

default[:openstack][:domk][:domain][:domain] = 'ccc.your.com'
default[:openstack][:domk][:domain][:ns] = 'ns.com'
default[:openstack][:domk][:domain][:reverse_ip_suffix] = '16.172,17.172'

default[:openstack][:domk][:azro][:auth_url] = 'https://your_keystone_public_auth:5000/v2.0'
default[:openstack][:domk][:azro][:ttl] = 300

default[:openstack][:domk][:azro][:azro_url] = 'http://azoro.com'
default[:openstack][:domk][:azro][:azro_domain] = 'azoro.com'
default[:openstack][:domk][:azro][:azro_subdomain] = 'ccc'
default[:openstack][:domk][:azro][:azro_user] = 'user'
default[:openstack][:domk][:azro][:azro_passwd] = 'password'
default[:openstack][:domk][:azro][:azro_type] = 'A'
default[:openstack][:domk][:azro][:azro_cname_domain] = ''

default[:openstack][:old_root_pem_path] = '/etc/ca-certificates/old_root.pem'

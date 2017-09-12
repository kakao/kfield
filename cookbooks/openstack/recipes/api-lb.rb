::Chef::Recipe.send(:include, Kakao::Openstack)

# 기본 셋업
_lbs = {
    'keystone_admin' => {
        :role => 'openstack-keystone',
        :port => 35357,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    },
    'keystone' => {
        :role => 'openstack-keystone',
        :port => 5000,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    },
    'glance-api' => {
        :role => 'glance-api',
        :port => 9292,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    },
    # glance-api의 local에서만 사용할 것임..
    # 'glance-registry' => {
    #     :role => 'glance-registry',
    #     :port => 9191,
    #     :mode => 'http',
    # },
    'nova-api-ec2' => {
        :role => 'nova-api',
        :port => 8773,
        :mode => 'http',
        :no_httpchk => true,
        :ssl => node[:openstack][:use_ssl],
    },
    'nova-api-compute' => {
        :role => 'nova-api',
        :port => 8774,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    },
    'nova-api-metadata' => {
        :role => 'nova-api',
        :port => 8775,
        :mode => 'http',
        # metadata는 remote addr로 판단하기 때문에 health_check에서는 무조건 오류가 발생하므로 httpchk는 제외
        :no_httpchk => true,
        # nova-api-metadata는 ssl을 사용하지 않는다.
        # - 외부에서 접속할 필요도 없고...
        # - neutron-metadata-agent도 https 지원하지 않고
        # - metadata-agent <--> nova-api 간도 자체 encrypt 하고 있다.
    },
    'dashboard' => {
        :role => 'horizon-server',
        :port => 80,
        :mode => 'http',
        :check_url => '/horizon/'
    },
    'neutron-api' => {
        :role => 'neutron-server',
        :port => 9696,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    },
    'novnc-proxy' => {
        :role => 'nova-novncproxy',
        :port => 6080,
        :mode => 'tcp',
        :ssl => node[:openstack][:use_ssl],
    },
}

if node[:openstack][:enabled_service].include?('ceilometer')
    _lbs['ceilometer-api'] = {
        :role => 'ceilometer-api',
        :port => 8777,
        :mode => 'tcp',
        :ssl => node[:openstack][:use_ssl],
    }
end

if node[:openstack][:enabled_service].include?('cinder')
    _lbs['cinder-api'] = {
        :role => 'cinder-api',
        :port => 8776,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    }
end

if node[:openstack][:enabled_service].include?('heat')
    _lbs['heat-api'] = {
        :role => 'heat-api',
        :port => 8004,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    }

    _lbs['heat-api-cfn'] = {
        :role => 'heat-api',
        :port => 8000,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    }

    _lbs['heat-api-cloudwatch'] = {
        :role => 'heat-api',
        :port => 8003,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    }
end

if node[:openstack][:enabled_service].include?('trove')
    _lbs['trove-api'] = {
        :role => 'trove-api',
        :port => 8779,
        :mode => 'http',
        :ssl => node[:openstack][:use_ssl],
    }
end

if node[:openstack][:enabled_service].include?('sahara')
    _lbs['sahara-all'] = {
        :role => 'sahara-all',
        :port => 8386,
        :mode => 'tcp',
        :ssl => node[:openstack][:use_ssl],
    }
end

_lbs['dashboard'][:params] = []
_lbs['dashboard'][:params] <<
  "redirect prefix http://#{node[:openstack][:redirect_url_to]} code 301 if { hdr(host) -i #{node[:openstack][:redirect_url_from]} }" if
    node[:openstack][:redirect_url_from] != '' && node[:openstack][:redirect_url_to] != ''

if node[:openstack][:use_ssl]
    _lbs['dashboard'][:params] << "redirect scheme https if !{ ssl_fc }"

    # 10.0.0.0/8이 다음쪽 IDC에서 사용하면서 내부 vpn cidr를 1.0.0.0/8로 바꾸었음
    private_cidr = %w"172.16.0.0/12 192.168.0.0/16 10.0.0.0/8"
    private_cidr << '1.0.0.0/8' if node[:ipaddress].start_with? '1.'

    _lbs['dashboard-ssl'] = {
        :role => 'horizon-server',
        :port => 443,
        :backend_port => 80,
        :mode => 'http',
        :check_url => '/horizon/',
        :ssl => node[:openstack][:use_ssl],
        :params => [
            "option http-server-close",
            "acl is-ssl             dst_port 443",
            "acl is-internal-net    src  #{private_cidr.join ' '}",
            "acl is-admin           url_beg  /horizon/admin",
            "http-request deny if !is-internal-net is-admin",
        ],
    }

    _lbs['dashboard-ssl'][:params] <<
      "redirect prefix http://#{node[:openstack][:redirect_url_to]} code 301 if { hdr(host) -i #{node[:openstack][:redirect_url_from]} }" if
        node[:openstack][:redirect_url_from] != '' && node[:openstack][:redirect_url_to] != ''
end

# 해당 롤로 서비스 되는 것이 있으면 추가
lbs = {}
_lbs.each do |name, item|
    nodes = nodes_by_role item[:role]
    next if nodes.empty?

    lbs[name] = item
end

if node[:haproxy][:install_method] == 'source'
  node.set['haproxy']['conf_dir'] = "#{node['haproxy']['source']['prefix']}/etc"
end

directory node['haproxy']['conf_dir']

# chainca는 site-ca, 중계 ca, root ca, private key 순서
# ssl cert
pem_file = "#{node[:haproxy][:conf_dir]}/ccc.pem"

cookbook_file pem_file do
  source node[:openstack][:lb][:pem_file]
  mode 00644
  only_if { node[:openstack][:use_ssl] }
  notifies :restart, 'service[haproxy]'
end

lbs.each do |name, option|
  nodes = nodes_by_role option[:role]

  _params = option[:params].nil? ? [] : option[:params]
  case option[:mode]
  when 'tcp'
    _params << 'option tcplog'
  when 'http'
    _params << 'option httplog'
    _params << "option httpchk#{option[:check_url].nil? ? '' : ' GET ' + option[:check_url]}" unless option[:no_httpchk]
  end

  node[:openstack][:bad_agents].each do |exp|
    _params << "acl is-bad-agent #{exp}"
  end
  _params << "http-request deny if is-bad-agent"

  _params << "reqadd x-forwarded-proto:\\ https" if option[:ssl]

  # for capture token
  _params << "capture request header X-Auth-Token len 32"

  bind_param = "0.0.0.0:#{option[:port]}"
  bind_param += " ssl crt #{pem_file}" if option[:ssl]

  backend_port = option[:backend_port].nil? ? option[:port] : option[:backend_port]

  haproxy_lb name do
    bind bind_param
    servers nodes.sort{ |a, b| a[:ipaddress] <=> b[:ipaddress]}.map {|n| "#{n[:hostname]} #{n[:ipaddress]}:#{backend_port} check"}
    mode option[:mode] unless option[:mode].nil?
    params _params
  end
end

# 이 로드밸러서를 접근하는 공식 hostname
node.set[:haproxy][:api_fqdn] = node[:openstack][:api_server]

# 개발 환경에만 적용되는 것인데... server check할 때 check interval 보다 response가 늦게 오면
# 다음번 health check를 위해서 healt check connection을 끊어버린다.
# 그래서 response가 정상적으로 온다고 해도 health check가 실패하는 현상이 발생함.
node.override[:haproxy][:defaults_timeouts][:check] = '5s' if check_environment_develop

# status
haproxy_lb 'stats' do
  bind "#{node[:ipaddress]}:9999"
  params([
    'stats enable',
    'stats hide-version',
    'stats realm Hello',
    'stats uri /proxy?stats',
    'stats auth status:status',
  ])
end

node.override[:haproxy][:global_options]['tune.ssl.default-dh-param'] = 2048

include_recipe 'haproxy'

cookbook_file '/etc/rsyslog.d/49-haproxy.conf' do
  source '49-haproxy.conf'
  mode 0644
end

bash 'for haproxy logging' do
  code <<-EOH
  sed -i 's/^\#$ModLoad imudp/$ModLoad imudp/g' /etc/rsyslog.conf
  sed -i 's/^\#$UDPServerRun 514/$UDPServerRun 514/g' /etc/rsyslog.conf
  service rsyslog restart
EOH
  only_if 'grep -q "#\$ModLoad imudp" /etc/rsyslog.conf && grep -q "#\$UDPServerRun 514" /etc/rsyslog.conf'
end

# logrotate haproxy
logrotate_app 'haproxy' do
  cookbook 'logrotate'
  path '/var/log/haproxy.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 syslog adm'
  postrotate 'reload rsyslog >/dev/null 2>&1 || true'
end

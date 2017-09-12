#
# Cookbook Name:: swift
# Recipe:: reverse-proxy
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

lbs = {}
lbs['swift-cluster'] = {
    :role => 'swift-proxy',
    :port => 443,
    :backend_port => 80,
    :mode => 'http',
    :check_url => '/healthcheck',
    :ssl => node[:openstack][:use_ssl],
    :params => [
        "option forwardfor",
        "option httpclose",
    ],
}

if node[:haproxy][:install_method] == 'source'
    node.set['haproxy']['conf_dir'] = "#{node['haproxy']['source']['prefix']}/etc"
end

directory node['haproxy']['conf_dir']

# chainca는 site-ca, 중계 ca, root ca, private key 순서
# ssl cert
pem_file = "#{node[:haproxy][:conf_dir]}/ccc.pem"

cookbook_file pem_file do
    source node['swift']['lb']['pem_file']
    owner "root"
    group "root"
    mode 00644
    only_if { node[:openstack][:use_ssl] }
    notifies :restart, "service[haproxy]"
end

lbs.each do |name, option|
    nodes = []
    if node[:swift][:all_proxy]
      nodes << node
    else
      nodes = search :node, "roles:#{option[:role]}"
    end

    _params = option[:params].nil? ? [] : option[:params]
    case option[:mode]
    when 'tcp'
        _params << 'option tcplog'
    when 'http'
        _params << 'option httplog'
        _params << "option httpchk#{option[:check_url].nil? ? '' : ' GET ' + option[:check_url]}" unless option[:no_httpchk]
    end

    bind_param = "0.0.0.0:#{option[:port]}"
    bind_param += " ssl crt #{pem_file}" if option[:ssl]

    backend_port = option[:backend_port].nil? ? option[:port] : option[:backend_port]

    haproxy_lb name do
        bind bind_param
        servers nodes.sort{ |a, b| a['swift']['proxy_server']['bind_ip'] <=> b['swift']['proxy_server']['bind_ip']}.map {|n| "#{n[:hostname]} #{n['swift']['proxy_server']['bind_ip']}:#{backend_port} check"}
        mode option[:mode] unless option[:mode].nil?
        params _params
    end
end

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

include_recipe "haproxy"

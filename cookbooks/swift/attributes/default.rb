#
# Cookbook Name:: swift
# Attribute:: default
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

default['swift']['owner']['user']['id'] = 1111
default['swift']['owner']['group']['id'] = 1111

default['swift']['hash']['prefix'] = 'changeme'
default['swift']['hash']['suffix'] = 'changeme'

default['swift']['storage_server']['audit_hour'] = 5

default['swift']['domain'] = node[:ipaddress]
default['swift']['proxy_server']['bind_ip'] = node[:ipaddress]
default['swift']['proxy_server']['bind_port'] = '80'

default['swift']['account_server']['bind_ip'] = node[:ipaddress]
default['swift']['account_server']['bind_port'] = '6002'
default['swift']['account_server']['accounts_audit_per_second'] = 10

default['swift']['container_server']['bind_ip'] = node[:ipaddress]
default['swift']['container_server']['bind_port'] = '6001'
default['swift']['container_server']['containers_audit_per_second'] = 10

default['swift']['object_server']['bind_ip'] = node[:ipaddress]
default['swift']['object_server']['bind_port'] = '6000'
default['swift']['object_server']['auditor_files_per_second'] = 1
default['swift']['object_server']['auditor_bytes_per_second'] = 500000
default['swift']['object_server']['autitor_zero_byte_files_per_second'] = 2

default['swift']['all_proxy'] = true
default['swift']['lb']['pem_file'] = 'your.com.pem'

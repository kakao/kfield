default[:sahara][:use_syslog] = true
default[:sahara][:log_dir] = '/var/log/sahara'

default[:sahara][:use_floating_ips] = false
default[:sahara][:use_neutron] = true
default[:sahara][:use_namespaces] = false

default[:sahara][:plugins] = ["vanilla","hdp","spark","cdh"]

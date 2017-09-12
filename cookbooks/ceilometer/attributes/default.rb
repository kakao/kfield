default[:ceilometer][:use_syslog] = true
default[:ceilometer][:log_dir] = '/var/log/ceilometer'
# generate with openssl rand -hex 10
default[:ceilometer][:telemetry_secret] = 'telemetry_secret'

default[:ceilometer][:api_workers] = 8
default[:ceilometer][:collector_workers] = 8
default[:ceilometer][:notification_workers] = 8

default[:ceilometer][:dispatcher] = 'database'

# kilo에서는 mongo에서 제공하는 ttl을 사용하지만, juno에서는 코드로 지움
default[:ceilometer][:database][:metering_time_to_live] = 2100

default[:ceilometer][:evaluation_service] = 'ceilometer.alarm.service.PartitionedAlarmService'

# pipeline의 metering interval의 기본값이 600으로 되어 있는데, 이것은 10분에 한번씩 metering 데이터를 보낸다는 이야기이다.
# 600은 autoscaling하는데 너무 부족한 값이라 적당히 변경함
default[:ceilometer][:pipeline][:interval] = 60

# apt_repository로 추가하면 apt-get update가 되어야 하는데,
# compile_time_update = true가 되어있으면, compiletime에 이미 apt-get update가 되어서
# apt_repository 이후에 수행이 안됨...
default['apt']['compile_time_update'] = false

default['mongodb3']['package']['version'] = '3.2.0'
default['mongodb3']['package']['repo']['url'] = 'http://ftp.daumkakao.com/ubuntu'
default['mongodb3']['package']['repo']['apt']['key'] = 'key'
default['mongodb3']['config']['mongod']['storage']['engine'] = 'wiredTiger'
# default 값이 hkp://keyserver.ubuntu.com:80 인데 이러면 apt 코드에서 프록시를 호출 못함..
default['mongodb3']['package']['repo']['apt']['keyserver'] = 'keyserver.ubuntu.com'

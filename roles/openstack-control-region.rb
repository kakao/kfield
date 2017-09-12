name 'openstack-control-region'
description 'OpenStack control region node'
run_list(
     'role[glance-api]', 'role[glance-registry]',
     'role[neutron-server]',
     'role[cinder-api]', 'role[cinder-volume]', 'role[cinder-scheduler]',
     'role[nova-api]', 'role[nova-cert]', 'role[nova-consoleauth]', 'role[nova-conductor]',
     'role[nova-novncproxy]', 'role[nova-scheduler]',
     'role[ceilometer-api]', 'role[ceilometer-agent-central]', 'role[ceilometer-collector]', 'role[ceilometer-alarm-notifier]', 'role[ceilometer-alarm-evaluator]',
     'role[heat-api]', 'role[heat-api-cfn]', 'role[heat-api-cloudwatch]', 'role[heat-engine]',
     'role[sahara-all]',
     'role[trove-api]', 'role[trove-taskmanager]', 'role[trove-conductor]',
)

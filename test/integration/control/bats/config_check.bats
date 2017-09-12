#!/usr/bin/env bats

@test "check zone based network" {
  grep zone_based_network_scheduler /etc/nova/nova.conf | grep true
}

@test "check inhouse sso" {
  grep inhouse_sso_auth /etc/keystone/keystone.conf
}

@test "check ecmp policy check" {
  grep floating_ip_address /etc/neutron/policy.json | grep admin_only
}

@test "check rabbitmq ulimit" {
  cat /proc/$(ps -ef | grep rabbitmq-server | grep -v grep | awk '{print $2}')/limits | grep 'Max open files' | grep 102400
}

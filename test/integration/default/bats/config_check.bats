#!/usr/bin/env bats

@test "check rabbitmq ulimit" {
  cat /proc/$(ps -ef | grep rabbitmq-server | grep -v grep | awk '{print $2}')/limits | grep 'Max open files' | grep 102400
}

@test "check rabbitmq was connected" {
  grep "Connected to AMQP server on" /var/log/nova/nova-conductor.log
}

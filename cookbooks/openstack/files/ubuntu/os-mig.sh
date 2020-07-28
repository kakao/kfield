#!/bin/bash
instance=$1
host=$2

nova live-migration --block_migrate $instance $host

sleep 1
while nova show $instance | grep -q MIGRATING; do
    sleep 1
done

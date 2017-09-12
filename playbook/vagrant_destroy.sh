#!/bin/bash

cd `dirname $0`/..

vagrant destroy

knife node list | grep '\.stack$' | xargs -L1 knife node delete -y
knife client list | grep '\.stack$' | xargs -L1 knife client delete -y

# 확실하게 하기 위해서 기존의 chef-zero 확인사살
chefzero_pid=`lsof -i tcp:4000 | awk '/ruby/{print $2}'`
test -z "$chefzero_pid" || kill -9 $chefzero_pid

sudo iptables -F
sudo iptables -X

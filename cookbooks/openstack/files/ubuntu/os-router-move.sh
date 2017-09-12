#!/bin/bash
# os-router-move.sh <router-name> <host-name>
set -e

target_router=$1
target_node=$2

function usage(){
    echo "Usage: `basename $0` ROUTER-NAME TARGET-NETWORK-NODE"
}

if [ -z "$target_router" -o -z  "$target_node" ]; then
    usage
    exit 1
fi

target_agent_id=`neutron agent-list | grep "$target_node" | awk '/L3 agent/{print $2}'`
if [ -z "$target_agent_id" ]; then
    echo "node $target_node running l3 agent not found"
    exit
fi

current_agent_id=`neutron l3-agent-list-hosting-router $target_router | head -n -1 | tail -n +4 | awk '{print $2}'`

test "$current_agent_id" && neutron l3-agent-router-remove $current_agent_id $target_router
neutron l3-agent-router-add $target_agent_id $target_router

# vim: nu aw ai

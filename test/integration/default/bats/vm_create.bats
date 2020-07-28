#!/usr/bin/env bats

load vm_create

@test "create neutron network" {
   echo "loadingg.. fucntion"
   run make_vm
   echo $output
   [ "$status" -eq 0 ]
}

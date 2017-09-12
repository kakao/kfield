#!/bin/bash
berks install
berks install

vagrant up db0.stack --no-provision
vagrant up —-no-provision

vm=( db0.stack control0.stack control0.stack lb0.stack control0.stack compute000.stack )

for i in ${vm[*]} ; do
    vagrant provision $i
done

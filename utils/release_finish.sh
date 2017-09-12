#!/bin/bash

git tag "inhouse-$(date +%Y.%m.%d).00"

function version_update {
  for cookbook in $cookbooks
  do
    echo "version dumping.. $cookbook"
    version=`/opt/chefdk/bin/knife spork bump $cookbook minor -o ./cookbooks 2>&1  | grep -i Success | awk -F " " '{print $5}' | sed s/\!//g`
  done
}

cookbooks=`ls -d cookbooks/*/ | cut -f2 -d'/'`
version=""
version_update
echo $version >& .build_version
git commit -a -m"[Jenkins] Finished bumping to $version"
##git push origin master
#upload_cookbook

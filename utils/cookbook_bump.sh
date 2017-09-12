#!/bin/bash

function upload_cookbook {
  for cookbook in $cookbooks
  do
    echo "uploading.. $cookbook"
    /opt/chefdk/bin/knife cookbook upload $cookbook -o ./cookbooks/ --force
  done
  echo "uploading.. environment"
  /opt/chefdk/bin/knife environment from file ./environments/stage.rb
  echo "uploading.. roles"
  /opt/chefdk/bin/knife role from file roles/*.rb
}

function version_update {
  for cookbook in $cookbooks
  do
    echo "version dumping.. $cookbook"
    version=`/opt/chefdk/bin/knife spork bump $cookbook patch -o ./cookbooks 2>&1  | grep -i Success | awk -F " " '{print $5}' | sed s/\!//g`
  done
}

#/usr/bin/git checkout  master
cookbooks=`ls -d cookbooks/*/ | cut -f2 -d'/'`
version=""
version_update
echo $version >& .build_version
git commit -a -m"[Jenkins] Finished bumping to $version"
##git push origin master
#upload_cookbook

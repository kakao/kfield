#!/bin/bash
#
# reinstall plugins
#
export PKG_CONFIG_PATH=/usr/lib/pkgconfig/ # http://leoh0.blogspot.kr/2014/09/ruby-libvirt.html
export http_proxy=http://proxy.server.io:8080
http_proxy=$http_proxy vagrant plugin install vagrant-berkshelf vagrant-mutate vagrant-cachier vagrant-chef-zero vagrant-omnibus vagrant-libvirt

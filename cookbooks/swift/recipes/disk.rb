#
# Cookbook Name:: swift
# Recipe:: disk
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

return unless node[:openstack][:enabled_service].include?(cookbook_name)

%w(xfsprogs parted util-linux).each do |pkg|
  package pkg
end

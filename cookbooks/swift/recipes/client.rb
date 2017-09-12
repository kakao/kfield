#
# Cookbook Name:: swift
# Recipe:: client
#
# Copyright 2014, Kakao Corp
#
# All rights reserved - Do Not Redistribute
#

python_pip 'python-swiftclient' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

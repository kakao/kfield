package 'python-dev'

python_pip 'python-memcached' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

python_pip 'python-keystoneclient' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end

cookbook_file '/etc/bash_completion.d/keystone' do
  source 'bash-completion'
end

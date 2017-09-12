
python_pip 'python-cinderclient' do
  virtualenv node[:openstack][:install][:source][:path]
  retries 5
  retry_delay 5
end


service = 'server'

link "/etc/init.d/#{cookbook_name}-#{service}" do
  to '/lib/init/upstart-job'
end

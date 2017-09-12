
include_recipe "#{cookbook_name}::install-domk"

template '/etc/domk.conf' do
  source 'domk.conf.erb'
  mode 0644
  notifies :run, 'execute[restart domk]'
end

execute 'restart domk' do
  command 'service domk restart'
  action :nothing
end

# logrotate domk
logrotate_app 'domk' do
  cookbook 'logrotate'
  path '/var/log/domk.log'
  options ['compress', 'missingok', 'delaycompress', 'notifempty']
  frequency node[:logrotate][:openstack][:frequency]
  rotate node[:logrotate][:openstack][:rotate]
  create '644 root root'
  postrotate 'restart domk >/dev/null 2>&1 || true'
end

if check_environment_production
  template '/root/watchdomk.sh' do
    source 'watchdomk.sh.erb'
    mode 00755
  end

  cron 'domk-watcher' do
    command '/root/watchdomk.sh'
  end
end

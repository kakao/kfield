
require 'uri'

%w(root vagrant).each do |user|
  next unless node['etc']['passwd'].include? user

  home_dir = node['etc']['passwd'][user]['dir']

  directory "#{ home_dir }/.pip" do
    mode '0755'
  end.run_action(:create)

  begin
    trusted_host = URI(node[:base][:pypi][:index_url]).host
  rescue
    Chef::Log.info 'You need to set pypi index-url!'
    trusted_host = ''
  end

  template "#{ home_dir }/.pip/pip.conf" do
    source 'pip.conf.erb'
    mode '0644'
    variables(
      :trusted_host => trusted_host
    )
  end.run_action(:create)

  template "#{ home_dir }/.pydistutils.cfg" do
    source '.pydistutils.cfg.erb'
    mode '0644'
  end.run_action(:create)
end

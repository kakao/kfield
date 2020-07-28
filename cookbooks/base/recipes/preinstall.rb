
# pre install gem

if platform_family?("debian")
  node.set[:apt][:compile_time_update] = true
  include_recipe "apt::default"
end

node.set[:'build-essential'][:compile_time] = true
include_recipe "build-essential::default"

package "libarchive-dev" do
  action :nothing
end.run_action(:install)

chef_gem 'libarchive-ruby' do
  version '0.0.3'
  action :nothing
end.run_action(:install)

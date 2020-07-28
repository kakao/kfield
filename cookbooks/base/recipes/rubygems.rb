# gem_package sources
if node['base']['rubygems']['gem_disable_default']
  execute 'gem sources --remove http://rubygems.org' do
    only_if "gem sources --list | grep 'http://rubygems.org'"
  end.run_action(:run)

  execute 'gem sources --remove https://rubygems.org' do
    only_if "gem sources --list | grep 'https://rubygems.org'"
  end.run_action(:run)
end

node['base']['rubygems']['gem_sources'].each do |source|
  execute "gem sources --add #{source}" do
    not_if "gem sources --list | grep '#{source}'"
  end.run_action(:run)
end

# chef_gem sources
if node['base']['rubygems']['chef_gem_disable_default']
  execute '/opt/chef/embedded/bin/gem sources --remove http://rubygems.org/' do
    only_if "/opt/chef/embedded/bin/gem sources --list | grep 'http://rubygems.org'"
  end.run_action(:run)

  execute '/opt/chef/embedded/bin/gem sources --remove https://rubygems.org/' do
    only_if "/opt/chef/embedded/bin/gem sources --list | grep 'https://rubygems.org'"
  end.run_action(:run)
end

node['base']['rubygems']['chef_gem_sources'].each do |source|
  execute "/opt/chef/embedded/bin/gem sources --add #{source}" do
    not_if "/opt/chef/embedded/bin/gem sources --list | grep '#{source}'"
  end.run_action(:run)
end

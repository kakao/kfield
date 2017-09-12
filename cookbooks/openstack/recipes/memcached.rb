include_recipe "memcached"

execute "memcached: restart" do
  command "service memcached restart"
  only_if { check_environment_jenkins }
end

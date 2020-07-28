sahara_enabled = node[:openstack][:enabled_service].include?('sahara')
return unless sahara_enabled

include_recipe "#{cookbook_name}::common"

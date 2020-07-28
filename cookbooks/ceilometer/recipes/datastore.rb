return unless node[:openstack][:enabled_service].include?(cookbook_name)

sysfs 'kernel/mm/transparent_hugepage/enabled' do
  value 'never'
  action :set
end

sysfs 'kernel/mm/transparent_hugepage/defrag' do
  value 'never'
  action :set
end

include_recipe 'mongodb3'

#
# add ceilometer user
#
package 'libsasl2-dev'

chef_gem 'mongo' do
  version '1.12.1'
  action :nothing
end.run_action(:install)

ceilometer_password = dbpassword_for 'ceilometer'

ruby_block "create ceilometer user" do
    block do
        require 'mongo'

        10.times do
            begin
                conn = Mongo::Connection.new('localhost', node[:mongodb3][:port])
                db = conn.db('ceilometer')
                db.add_user 'ceilometer', ceilometer_password, %w"readWrite dbAdmin"
                break
            rescue
                Chef::Log.info "waiting service up: mongo..."
                sleep 5
            end
        end
    end
end

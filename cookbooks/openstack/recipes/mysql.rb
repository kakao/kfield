::Chef::Recipe.send(:include, Kakao::Openstack)

# region을 사용하는 경우는 regions 혹은 region_name이 있음..
#if not node[:openstack][:regions].nil? or not node[:openstack][:region_name].nil?
unless (node[:openstack][:regions].nil? and node[:openstack][:region_name].nil?)
    databases = []
    # region supports
    unless ( node[:openstack][:regions].nil? or node[:openstack][:region_name].nil? )
        fail "You can't specify regions and region_name at the same time."
    end

    # 공통 서비스에는 keystone만 필요
    if not node[:openstack][:regions].nil?
        databases << "keystone"
    end

    # region services에는 다른 것도 필요함...
    if not node[:openstack][:region_name].nil?
        databases += %w'glance neutron nova'
    end
else
    # no regions
    databases = %w"keystone glance neutron nova"
end

# glance 데이터베이스를 포함하는 것은 region controller의 데이터베이스를 의미한다.
# region controller database에 필요한 DB를 추가한다.
if databases.include? 'glance'
    databases << 'cinder' if node[:openstack][:enabled_service].include?('cinder')
    databases << 'heat' if node[:openstack][:enabled_service].include?('heat')
    databases << 'trove' if node[:openstack][:enabled_service].include?('trove')
    databases << 'sahara' if node[:openstack][:enabled_service].include?('sahara')
end

connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node[:mysqld][:root_password],
}

mysql2_chef_gem 'default' do
    action :nothing
end.run_action(:install)

databases.each do |db|
  mysql_database db do
    connection connection_info
    action :create
  end

  password = dbpassword_for db
  mysql_database_user db do
    connection connection_info
    password password
    database_name db
    host '%'
    privileges [:all]
    action [:create, :grant]
  end
end

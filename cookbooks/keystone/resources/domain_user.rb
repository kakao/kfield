
actions :create
default_action :create

attribute :domain_admin_name, :kind_of => String, :name_attribute => true
attribute :domain_name, :kind_of => String, :default => nil
attribute :domain_admin_password, :kind_of => String, :default => nil
attribute :auth_addr, :kind_of => String, :required => true

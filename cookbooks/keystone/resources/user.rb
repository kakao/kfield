
actions :create
default_action :create

attribute :username, :kind_of => String, :name_attribute => true
attribute :password, :kind_of => String, :required => true
attribute :email, :kind_of => String, :default => nil
attribute :tenant_id, :kind_of => String, :default => nil
attribute :tenant, :kind_of => String, :default => nil
attribute :enabled, :kind_of => [TrueClass, FalseClass], :default => true
attribute :auth_addr, :kind_of => String, :required => true

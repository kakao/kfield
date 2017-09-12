
actions :add
default_action :add

attribute :user, :kind_of => String, :name_attribute => true
attribute :tenant, :kind_of => String, :required => true
attribute :role, :kind_of => String, :required => true
attribute :auth_addr, :kind_of => String, :required => true

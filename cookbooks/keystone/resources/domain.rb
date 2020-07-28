
actions :create
default_action :create

attribute :domain_name, :kind_of => String, :name_attribute => true
attribute :auth_addr, :kind_of => String, :required => true

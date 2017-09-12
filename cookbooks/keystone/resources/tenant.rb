
actions :create
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :description, :kind_of => String, :default => ''
attribute :enabled, :kind_of => [TrueClass, FalseClass], :default => true
attribute :auth_addr, :kind_of => String, :required => true

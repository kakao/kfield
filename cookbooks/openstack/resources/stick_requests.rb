actions :update
default_action :update

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String, :required => true

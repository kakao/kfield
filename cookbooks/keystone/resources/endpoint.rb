
actions :create
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :region, :kind_of => String, :default => "RegionOne"
attribute :public_url, :kind_of => String, :required => true
attribute :internal_url, :kind_of => String, :required => true
attribute :admin_url, :kind_of => String, :required => true
attribute :description, :kind_of => String, :required => true
attribute :auth_addr, :kind_of => String, :required => true

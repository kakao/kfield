default[:glance][:use_syslog] = true
default[:glance][:stores] = "file,http,rbd,swift"

default[:glance][:cloud_images] = []

# file, ceph, swift
default[:glance][:backend] = 'file'

default[:glance][:show_image_direct_url] = false

# nil to number of CPUs
default[:glance][:workers] = nil

# ceph
default[:glance][:rbd_pool] = 'images'
default[:glance][:rbd_key] = nil

# swift
default[:glance][:swift][:region] = 'busan-v1'
default[:glance][:swift][:auth_address] = "127.0.0.1:5000/v2.0/"
default[:glance][:swift][:auth_tenant] = "jdoe"
default[:glance][:swift][:auth_user] = "jdoe"
default[:glance][:swift][:auth_password] = "password"
default[:glance][:swift][:container] = "glance"

case node[:glance][:backend]
when 'file'
    default[:glance][:default_store] = 'file'
when 'ceph'
    default[:glance][:default_store] = 'rbd'
when 'swift'
	default[:glance][:default_store] = 'swift'
end

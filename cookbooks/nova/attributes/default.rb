default[:nova][:use_syslog] = true
default[:nova][:log_dir] = '/var/log/nova'
default[:nova][:state_path] = '/var/lib/nova'

# only nova-api
#
# zone이 없을 경우는 nova로 availability zone이 표시되는데, 그 것을 대체한다.
# zone의 개념은 사라졌으며 그 기능은 host aggregation 기능으로 처리한다.
default[:nova][:default_availability_zone] = nil

default[:nova][:enabled_apis] = 'ec2,osapi_compute,metadata'
default[:nova][:ec2_private_dns_show_ip] = true

#
# Compute Services
#
default[:nova][:cpu_allocation_ratio] = 16.0
default[:nova][:disk_allocation_ratio] = 1.0
default[:nova][:ram_allocation_ratio] = 1.0
default[:nova][:reserved_host_memory_mb] = 512
default[:nova][:scheduler_default_filters] = \
    'AggregateInstanceExtraSpecsFilter,RetryFilter,AvailabilityZoneFilter,' \
    'RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,' \
    'ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter'
default[:nova][:scheduler_weight_classes] = 'kakao.openstack.nova.weights.RAMStackWeigher'
# RAMStackWeigher options
default[:nova][:ram_weight_stack_host_free_ram] = 8192
default[:nova][:ram_weight_stack_min] = 5120

default[:nova][:scheduler_host_subset_size] = 10
# /32 에서는 1 : n network, subnet
default[:nova][:zone_based_network_scheduler] = true

default[:nova][:network_api_class] = 'nova.network.neutronv2.api.API'
default[:nova][:security_group_api] = 'neutron'

# config drive
default[:nova][:force_config_drive] = 'False'

# kvm driver
default[:nova][:hypervisor] = 'kvm'

# kvm options
default[:nova][:libvirt_type] = 'kvm'
default[:nova][:compute_driver] = 'nova.virt.libvirt.LibvirtDriver'
default[:nova][:vif_driver] = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'
default[:nova][:linuxnet_interface_driver] = 'nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver'
default[:nova][:firewall_driver] = 'nova.virt.firewall.NoopFirewallDriver'
default[:nova][:vif_plugging_is_fatal] = false   # ml2 + openvswitch 이면 false로...
default[:nova][:vif_plugging_timeout] = 0 # ml2 + openvswitch 이면 0으로...

default[:nova][:use_live_migration] = true
default[:nova][:storage_backend] = 'local'
default[:nova][:use_cow_images] = true
default[:nova][:force_raw_images] = true

default[:nova][:allow_instance_snapshots] = true

# live_migration이 아니고 nova migrate 명령
default[:nova][:use_migration] = true
default[:nova][:block_migration_flag] = 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_NON_SHARED_INC,VIR_MIGRATE_LIVE'

default[:nova][:ec2_workers] = nil
default[:nova][:compute_workers] = nil
default[:nova][:metadata_workers] = nil
default[:nova][:conductor_workers] = nil

# 사용시 conductor 안쓰고 로컬에 세팅된 db connection으로 db를 세팅(로컬 nova.conf에 db 세팅 안하면 에러 및 agent health check가 안됨)
default[:nova][:conductor][:use_local] = false

# default quota
default[:nova][:quota][:cores] = 40
default[:nova][:quota][:fixed_ips] = -1
default[:nova][:quota][:floating_ips] = 10
default[:nova][:quota][:injected_file_content_bytes] = 10240
default[:nova][:quota][:injected_file_path_length] = 255
default[:nova][:quota][:injected_files] = 5
default[:nova][:quota][:instances] = 20
default[:nova][:quota][:key_pairs] = 100
default[:nova][:quota][:metadata_items] = 128
default[:nova][:quota][:ram] = 100 * 1024
default[:nova][:quota][:security_group_rules] = 20
default[:nova][:quota][:security_groups] = 10
# api에서 리턴하는 최대 갯수, domk에서 전에 인스턴스를 가져오므로 그 값보다 많아야..
# TODO - pagination 또는 db를 직접 query하는 API를 만드는게 좋을 듯
default[:nova][:osapi_max_limit] = 10000

if node[:nova][:use_live_migration]
    def_option = 'VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_LIVE'
    case node[:nova][:storage_backend]
    when 'glusterfs'
        default[:nova][:live_migration_flag] = "%{def_option}, VIR_MIGRATE_UNSAFE"
    else
        default[:nova][:live_migration_flag] = def_option
    end
else
    default[:nova][:live_migration_flag] = nil
end

default[:nova][:blockdev_scheduler] = 'deadline'

# nova compute tunings
default[:nova][:tunable][:swappiness] = 1

default[:nova][:ceilometer][:instance_usage_audit_period] = 'hour'
default[:nova][:ceilometer][:notify_on_state_change] = 'vm_and_task_state'

default[:nova][:dashboard_console] = 'novnc'

default[:nova][:multi_instance_display_name_template] = '%(name)s-%(uuid).8s'

default[:nova][:instance_name_check_regex] = '^([a-zA-Z0-9][-]*){0,62}([a-zA-Z0-9])$'
default[:nova][:enable_dns_check] = false
default[:nova][:enable_instance_name_check] = true
default[:nova][:enable_instance_name_prefix] = false
default[:nova][:instance_name_prefix] = ''

default[:nova][:vendordata_jsonfile_path] = nil
default[:nova][:allow_only_stopped_vm_for_snapshoting] = false

# policy
default[:nova][:policy][:owner_migration] = true

# nova compute에서 ceph 접근에 사용함
# cat /dev/urandom | LC_CTYPE=C tr -dc A-Za-z0-9_ | head -c 16 # 아니면 # uuidgen -r
default[:nova][:ceph_secret_uuid] = '<none>'

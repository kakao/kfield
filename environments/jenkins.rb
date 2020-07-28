name "jenkins"
description "OpenStack jenkins environment"
cookbook_versions

default_attributes(
  :omnibus_updater=>{
    :kill_chef_on_upgrade => false,
    :disabled  => true
  }
)

override_attributes(
    :chef_client => {
        :server_url => "https://chef.stack",
    },
    :openstack => {
        :debug => {
            :global => true,
        },
        :api_server => 'devel-api.your.com',
        :database => {
            :hostname => 'db0.stack',
            :use_managed_database => false,
        },
        :enabled_service => %w{cinder heat swift sahara trove ceilometer},
        :notification_driver => [],
    },
    :horizon => {
        :help_url => 'https://your_guide/',
        :secret_key => 'your_secret_key',
    },
    :glance => {
        :backend => 'swift',
        :swift => {
          :auth_address => 'https://your_keystone_public_auth:5000/v2.0',
          :auth_tenant => 'CIA',
          :auth_user => 'ccc',
          :auth_password => 'ccc',
          :container => 'kfield-images',
        },
        :cloud_images => [
            {
                :name => 'cirros-0.3.1',
                :url => 'http://your_repository/cirros-0.3.1-x86_64-disk.img',
            },
        ],
    },
    :cinder => {
        :backend => 'ceph',
        # ceph osd pool create volumes 128
        # ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images'
        :rbd_pool => 'volumes',
        :rbd_user => 'volumes',
        :rbd_key => 'your_secret_key',
    },
    :nova => {
        :ram_allocation_ratio => 1.5, # memory over committing
        :ceph_secret_uuid => 'your_ceph_uuid',
    },
    :neutron => {
        :tenant_network_type => 'vlan',
        :network_vlan_ranges => 'default:100:200',

        :api_workers => 2,
        :rpc_workers => 2,

        :dnsmasq_dns_servers => '10.252.0.1',
        :dsr_mode => '',   # l3dsr_global or l2dsr_vip or ''
    },
    :ceilometer => {
        :telemetry_secret => '950cfb1cdb9f51052ebd',
    },
    :heat => {
        :workers => {
            :api => 2,
            :api_cloudwatch => 2,
            :api_cfn => 2,
            :engine => 2,
        },
    },
    :ceph => {
        :config => {
            :fsid => 'your_fsid',
            :mon_initial_members => 'mon1.com,mon2.com,mon3.com',
            :mon_hosts => ['172.16.94.25', '172.16.94.26', '172.16.94.27'],
            :global => {
                :auth_supported => 'cephx',
                :osd_journal_size => 2048,
                :filestore_xattr_use_omap => 'true',
            },
        },
    },
    :rabbitmq => {
        :erlang_cookie => 'erlang_cookie_id',
    },
    :swift => {
        :domain => 'devel-swift.your.com',
        :hash => {
            :prefix => 'c847bdde-b8a3-4604-8a16-8f50521a1bec',
            :suffix => '866dc88c-ea47-483b-b6f3-e82524dafa73',
        },
        :proxy_server => {
          :bind_ip => '127.0.0.1',
        },
    },
    :kibana => {
        :version => '3',
    },
    :logrotate => {
        :openstack => {
            :frequency => 'daily',
            :rotate => 4,
        },
    },
    :java=> {
      :jdk_version => '7'
    },
    :logstash=> {
      :instance => { :server => {} }
    },
    :rsyslog=> {
      :server_search => 'role:logstash_server',
      :port => '5959',
    },
)

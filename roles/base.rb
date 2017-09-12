name 'base'
description 'The base role'
run_list(
    "recipe[base::pypi]",
    "recipe[base::rubygems]",
    "recipe[base]",
    "recipe[chef-client::config]",
    "recipe[chef-client::delete_validation]",
    "recipe[omnibus_updater]",
    "recipe[kakao]",
)

default_attributes(
  :ubuntu => {
    :archive_url => 'http://ftp.daumkakao.com',
    :server_url => 'http://ftp.daumkakao.com'
  }
)

override_attributes(
    :ceph => {
        :debian => {
            :stable => {
                :repository => 'http://yoursite.com/ceph/debian',
                :repository_key => 'http://yoursite.com/ceph/keys/release.asc',
            }
        },
        :install_debug => false,
    },
    :chef_client => {
        # -f 옵션은 chef-client의 fork-bomb를 막는다.
        :daemon_options => ['-f'],
        :config => {
            :log_level => 'info',
            :verify_api_cert => false,
            :report_handlers => [
                {"class" => "LastRunUpdateHandler", "arguments" => []},
            ]
        },
        :load_gems => {
            "knife-lastrun" => { :require_name => "lastrun_update", :action => :nothing },
        },
        :logrotate => {
            :rotate => 30,
        },
        :log_rotation => {
            :postrotate => '/etc/init.d/chef-client reload >/dev/null 2>&1 || true',
            :options => ['compress', 'missingok', 'delaycompress', 'notifempty'],
        },
    },
    :omnibus_updater => {
        :version => '12.4.1-1',
        :direct_url => "http://ftp.yoursite.com//chef/chef_12.4.1-1_amd64.deb",
    },
    :ohai => {
        :disabled_plugins => [
            :Azure,
            :Cloud,
            :CloudV2,
            :C,
            :DigitalOcean,
            :DMI,
            :EC2,
            :Erlang,
            :Eucalyptus,
            :GCE,
            :Go,
            :Groovy,
            :IpScopes,
            :Java,
            :Joyent,
            :Keys,
            :Languages,
            :Linode,
            :Lua,
            :Mono,
            :NetworkListeners,
            :Nodejs,
            :Ohai,
            :OhaiTime,
            :Openstack,
            :Perl,
            :PHP,
            :PowerShell,
            :Python,
            :Rackspace,
            :RootGroup,
            :Ruby,
            :Rust,
            :SSHHostKey,
            :Uptime,
            :Virtualization,
            :VirtualizationInfo,
            :Zpools,
        ],
    },
    :logrotate => {
        :openstack => {
            :frequency => 'weekly',
            :rotate => 30,
        },
    },
    :kakao => {
        :ssh_key => {
            "root" => "ssh-rsa AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA root@localhost",
        },
    },
)

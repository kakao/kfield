# Setup

### OS environment:

Ubuntu 14.04 (trusty) recommended.

### user:

you can use non root user.

### Clean up your gems:

    gem uninstall chef knife vagrant berkshelf -aIx

### Clone the repo

    git clone https://github.com/kakao/kfield.git
    
### install base package

    sudo apt-get install -qqy make gcc g++ autoconf
    

## Ruby

### Install chefDK for using embedded ruby

Install chefDK from https://downloads.getchef.com/chef-dk/

    sudo dpkg -i chefdk_0.4.0-1_amd64.deb

add chefdk path
    
    eval "$(chef shell-init bash)"
    echo 'eval "$(chef shell-init bash)"' >> ~/.bashrc # for next shell login

## libvirt

### setup libvirt and related packages

install packages

    sudo apt-get install -qqy libxslt1-dev libxml2-dev libvirt-dev libvirt-bin dnsmasq qemu-kvm qemu-utils
    
use dnsmasq for only 127.0.0.1

    sudo sed -i 's/#listen-address=/listen-address=127.0.0.1/g' /etc/dnsmasq.conf
    sudo sed -ri 's/^(except-interface)/#\0/' /etc/dnsmasq.d/libvirt-bin
    
adduser into libvirtd group

    sudo adduser `id -un` libvirtd # need relogin

**NOTICE!! YOU MUST RELOGIN SHELL using virsh for non root user!!**

delete default network

    virsh net-undefine default
    
setup virsh completion for bash

    https_proxy=proxy.server.io:8080 curl -s https://launchpadlibrarian.net/82049364/virsh | sudo tee /etc/bash_completion.d/virsh
    source /etc/bash_completion.d/virsh


## network

### install ovs

    sudo apt-get install -qqy openvswitch-switch

### setup network and script

delete resolfconf

    sudo apt-get purge -qqy resolvconf

setup network

    sudo iptables -t nat -A POSTROUTING -j MASQUERADE -o eth0
    sudo sysctl net.ipv4.ip_forward=1
    echo '''# Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
    #     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
    search stack kr.your.com kr2.your.com kr3.your.com
    nameserver 127.0.0.1
    nameserver 10.20.30.40''' | tee /etc/resolv.conf
    sudo service dnsmasq restart

setting script for rebooting

	sudo sed -i '/exit 0/d' /etc/rc.local
	echo """iptables -t nat -A POSTROUTING -j MASQUERADE -o eth0
	sysctl net.ipv4.ip_forward=1
	echo '''# Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
	#     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
	search stack kr.your.com kr2.your.com kr3.your.com
	nameserver 127.0.0.1
	nameserver 10.20.30.40''' | tee /etc/resolv.conf
	service dnsmasq restart
	exit 0""" | sudo tee -a /etc/rc.local

## Vagrant

### Get vagrant

Need vagrant installed http://www.vagrantup.com/downloads.html

    sudo dpkg -i vagrant_1.7.4_x86_64.deb

use our ruby mirror
    /opt/vagrant/embedded/bin/gem source --add http://ftp.daumkakao.com/rubygems/
    /opt/vagrant/embedded/bin/gem source --remove https://rubygems.org/

setup vagrant bash completion

     sudo https_proxy=proxy.server.io:8080 wget https://raw.github.com/kura/vagrant-bash-completion/master/etc/bash_completion.d/vagrant -O /etc/bash_completion.d/vagrant

### Vagrant Plugins
The repo has a handy script for setting them up. Simply run it

     bash -x vagrant_plugins.sh

FYI, vagrant-cachier sets up a local cache for packages and such going to the vagrant boxes, and can help your vagrant boxes get built faster.
And check vagrant-libvirt >= 0.0.24.


### Get Vagrant basebox for vagrant-libvirt

    vagrant box add trusty64 http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box
    vagrant mutate trusty64 libvirt
    export BERKSHELF=true
    echo "export BERKSHELF_PATH=$(pwd)/.berkshelf" >> ~/.bashrc
    berks install
    berks install # twice

### delete warning

if below message makes you annoying,

    W, [2015-02-11T15:14:19.058573 #19603]  WARN -- : Terminating task: type=:finalizer, meta={:method_name=>:__shutdown__}, status=:receiving
            Celluloid::TaskFiber backtrace unavailable. Please try `Celluloid.task_class = Celluloid::TaskThread` if you need backtraces here.
    W, [2015-02-11T15:14:19.067521 #19603]  WARN -- : Terminating task: type=:finalizer, meta={:method_name=>:__shutdown__}, status=:receiving
            Celluloid::TaskFiber backtrace unavailable. Please try `Celluloid.task_class = Celluloid::TaskThread` if you need backtraces here.
    W, [2015-02-11T15:14:19.071279 #19603]  WARN -- : Terminating task: type=:finalizer, meta={:method_name=>:__shutdown__}, status=:receiving
            Celluloid::TaskFiber backtrace unavailable. Please try `Celluloid.task_class = Celluloid::TaskThread` if you need backtraces here.

then find celluloid code and

    ~/.vagrant.d/gems/gems/celluloid-0.16.0/lib/celluloid/tasks.rb

comment these codes

    115     def terminate
    116       raise "Cannot terminate an exclusive task" if exclusive?
    117
    118       if running?
    119         #Logger.with_backtrace(backtrace) do |logger|
    120         #  logger.warn "Terminating task: type=#{@type.inspect}, meta=#{@meta.inspect}, status=#{@status.inspect}"
    121         #end
    122         exception = Task::TerminatedError.new("task was terminated")
    123         exception.set_backtrace(caller)

### ssh setting

    echo '''Host *.stack db0 lb0 control0 compute000 swift0 glb0 gdb0 gcontrol0
	  User vagrant
	  UserKnownHostsFile /dev/null
	  StrictHostKeyChecking no
	  PasswordAuthentication no
	  IdentityFile /home/vagrant/Project/ITF/kfield/.vagrant/machines/%h.stack/libvirt/private_key
	  IdentitiesOnly yes
	  LogLevel FATAL
	''' | tee /home/vagrant/.ssh/config

##  Gems

### Install necessary gems
    gem install bundler test-kitchen kitchen-vagrant

## Berks
Create ~/.berkshelf/config.json.

_NOTE:_ If you are running berks from the repo or using the cooks command this is optional.

    cat  <<EOF> ~/.berkshelf/config.json
    {
      "ssl": {
          "verify": false
        }
    }
    EOF

## Build the VM's

    vagrant up

This command will sudo to setup port forwards we have to have due to some bugs in chef11.

After you have this setup you should have openstack on 9 node in HA mode, and a chef server.
`knife` commands used from the root of the repo will execute against the server.

The available vagrant virtual machine configurations are defined in config/vms-default.json.
The environment variable 'vms_config' can be used to select additional configuration. i.e.

    export vms_config="vms-XXX.json"

You can also switch to other setup by specifying 'vagrant_infra' arg as follows. This should deploy 4 nodes setup.

    vagrant_infra=other_default.rb vagrant up

### build swift test

and run below script in the swift0.stack

    /vagrant/utils/swift_setup.sh

## Use Openstack to build VMs for you environment
if your workstation is too busy to create another instances for your developement, you can use openstacks'vm.

### install openstack plugin
To do this, the procedure is simple. Install vagrant-openstack-plugin

    vagrant plugin install vagrant-openstack-plugin

### setup openstack environment.
refer the Vagrantfile, and config/vms-inhouse.json.  you can easily understand how it works. put your account and authentication information to Vagrantfile.
_NOTE:_ For security reason, openstack authentication password should be set in the environemnt value.

    export OS_PASSWORD='your account password(i.e. ldap password)'

### select openstack and provisioner
You should add vagrant provider selection option like below. The environment value is VAGRANT_PROVIDER.

     VAGRANT_PROVIDER=openstack vms_config=vms-inhouse.json vagrant up

### SSH to your instances

__Server__
From the root of the repo you can ssh to the server with vagrant

    vagrant ssh

__nodes__
In the `vagrant` directory you can see your provisioned nodes. you can cd to these directories and `vagrant ssh` into nodes.

## Use Kfield As deploy center.
In the Kfield, you can access every enviroment like your development workstation, stage and production chef through chefvm.
chefvm is just like rvm. but you don't have to have .chefvmrc file in your workstation.

### install chefvm.

    # Chefvm will create a symlink between (~/.chefvm -> ~/.chef ), make sure you have no ~/.chef directory before installing
    mv ~/.chef ~/.chef.bak
    git clone https://github.com/trobrock/chefvm.git ~/.chefvm
    ~/.chefvm/bin/chefvm init # Follow these instructions

    # add this line to your .bash_profile
    eval "$(/home/vagrant/.chefvm/bin/chefvm init -)"

### Usage
like rvm, you can create chef name space and use like below

    # Use a specific config
    chefvm use {YOUR_CHEF_CONFIG|default}
    # or
    chefvm YOUR_CHEF_CONFIG

    # Set your default config
    chefvm default YOUR_CHEF_CONFIG

    # List your configurations, including current and default
    chefvm list

    # Create a new config
    chefvm create YOUR_CHEF_CONFIG

    # Delete a config
    chefvm delete YOUR_CHEF_CONFIG

    # Copy a config
    chefvm copy SRC_CONFIG DEST_CONFIG

    # Rename a config
    chefvm rename OLD_CONFIG NEW_CONFIG

    # Open a config directory in $EDITOR
    chefvm edit YOUR_CHEF_CONFIG

    # Update chefvm to the latest
    chefvm update

### more details
follow README in chefvm git repo

## License

This software is licensed under the [Apache 2 license](LICENSE.txt), quoted below.

Copyright 2017 Kakao Corp. <http://www.kakaocorp.com>

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this project except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

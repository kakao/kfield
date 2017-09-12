require 'json'

vms_config = ENV['VAGRANT_VMS_CONFIG'] || 'vms-minimal.json'
json = open(File.dirname(__FILE__) + "/config/#{vms_config}").read
vms = JSON.parse(json)['vms']

networks = proc do |box|
  provider_network['config']['ifaces'].each do |br|
    box.vm.network :public_network, :dev => br['name'], :mode => 'bridge', :type => 'bridge', :ovs => true, :model_type => 'virtio', ip: '0.0.0.0'
  end
end

vagrant_attrs = {
  'rubygems' => {
    'gem_disable_default' => false,
    'chef_gem_disable_default' => false
  },
  'authorization' => {
    'sudo' => {
      'users' => ['deploy'],
      'passwordless' => true
    }
  }
}

vm_config = proc do |box, cpus, memory|
  box.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', memory]
  end

  box.vm.provider :libvirt do |domain|
    domain.cpus = cpus
    domain.memory = memory
    domain.nested = true
    domain.volume_cache = 'none'
  end
end

vms.map do |name, param|
  config.vm.define name.to_sym do |box|
    box.vm.hostname = name
    if param.key? 'forward'
      param['forward'].each do |f|
        host, guest = f.to_s.split ':'
        config.vm.network :forwarded_port, guest: guest, host: host, auto_correct: true
      end
    end
    networks.call box
    cpus = (param['cpus'] || 1)
    vm_config.call box, cpus, param['memory']
    # copy kakao apt_list
    copy_hosts = "cp #{File.join('/vagrant/',"/utils/#{ENV['UBUNTU_RELEASE']||'trusty'}-sources.list")} /etc/apt/sources.list && sudo apt-get clean && sudo apt-get update"
    box.vm.provision :shell, :inline => copy_hosts
    box.vm.provision :shell, :inline => 'sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime'
    box.vm.provision :shell, :inline => 'sudo apt-get install -y vim curl'
    box.vm.provision :chef_client do |chef|
      chef.environment = param['environment'] || 'devel'
      chef.custom_config_path = './config/disable_ohai_plugin.chef'
      chef.run_list = param['run_list']
      json_attr=Hash.new
      if param.key? 'json'
        json_attr = json_attr.merge(param['json'])
      end
      chef.json = json_attr.merge(vagrant_attrs)
    end
  end
end

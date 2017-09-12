require "json"

vms_config = ENV['vms_config'] || "vms-default.json"
json = open(File.dirname(__FILE__) + "/config/#{vms_config}").read
vms = JSON.parse(json)["vms"]


vagrant_attrs = {
  :rubygems =>{
    :gem_disable_default => false,
    :chef_gem_disable_default => false
  },
  "authorization" => {
    "sudo" => {
      "users" => [ "deploy" ],
      "passwordless" => true
    }
  },
}

vms.map do |name, param|
  config.vm.define name.to_sym do |box|
    box.vm.hostname = name
    if param.has_key? 'forward'
      param['forward'].each do |f|
        host, guest = f.to_s.split ":"
        config.vm.network :forwarded_port, guest: guest, host: host, auto_correct: true
      end
    end
    #copy kakao apt_list
    copy_hosts = "cp #{File.join('/vagrant/','/utils/sources.list')} /etc/apt/sources.list && sudo apt-get update"
    box.vm.provision :shell, :inline => copy_hosts
  
    box.vm.provision :chef_client do |chef|
      chef.environment = "test"
      chef.run_list = param["run_list"]
      chef.json = vagrant_attrs
      chef.delete_node = true
      chef.delete_client= true
    end
  end
end

# vim: ft=ruby:

cfg_dir = File.expand_path File.dirname(__FILE__)
require_relative "config/lib/custom_action/plugin"
require_relative "config/lib/custom_action/omnibus_monkey_patch"
require_relative "config/lib/colorize/color"
require_relative "config/lib/local_ip"

Vagrant.configure('2') do |config|
  # omnibus를 특정사이트에서 다운로드 받아야 함. 버전을 변경하면 아래의 작업이 필요함
  # - omnibus package를 다운로드
  config.omnibus.chef_version = "12.4.1"
  config.omnibus.install_url = "http://ftp.yoursite.com/chef/install.sh"
  provider = (ENV['VAGRANT_DEFAULT_PROVIDER'] || :libvirt).to_sym
  provider_networks = (ENV['VAGRANT_PROVIDER_NETWORK'] || :"provider-network-default.json")
  json = open(File.dirname(__FILE__) + "/config/#{provider_networks}").read

  puts "PROVIDER: #{provider.to_s}".pink
  case provider
  when :libvirt
    if (ENV['BERKSHELF'] || false )
      config.chef_zero.environments = "#{cfg_dir}/.json/environments/"
      config.chef_zero.data_bags = "#{cfg_dir}/.json/data_bags/"
      config.chef_zero.roles = "#{cfg_dir}/.json/roles/"
      config.berkshelf.enabled = true
    else
      config.berkshelf.enabled = false
    end
    provider_network = JSON.parse(json)["libvirt"]
    config.vm.box_url = "http://ftp.yoursite.com//vagrant/ubuntu/"+(ENV['UBUNTU_RELEASE'] || "trusty") + "64" + ".box"
    config.vm.box = (ENV['UBUNTU_RELEASE'] || "trusty") + "64"
    config.vm.provider "libvirt" do |vb|
      vb.graphics_ip='0.0.0.0'
      vb.management_network_address = provider_network["provider"]["management_network_address"]
      vb.management_network_mode = provider_network["provider"]["management_network_mode"]
      vb.management_network_name = provider_network["provider"]["management_network_name"]
      config.custom_action.config["provider_network"] = provider_network
    end
  when :openstack
    infra = ENV['VAGRANT_INFRA'] || 'config-openstack.rb'
    instance_eval(IO.read("#{cfg_dir}/config/#{infra}"))
  else
    puts "Not Implemented"
  end

  infra = ENV['VAGRANT_INFRA'] || 'config-default.rb'
  instance_eval(IO.read("#{cfg_dir}/config/#{infra}"))
end

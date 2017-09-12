require "json"
json = open(File.dirname(__FILE__) + "/config/vms-openstack.json").read
openstack = JSON.parse(json)["openstack"]["#{stage}"]

config.vm.box = 'dummy'
config.vm.box_url = 'https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box'
config.ssh.private_key_path = "~/.ssh/cloud.key"

config.vm.provider :openstack do |os|
  os.username = openstack["user"]
  os.flavor   = openstack["flavor"]
  os.image    = openstack["image"]
  os.tenant   = openstack["tenant"] # optional
  os.keypair_name = openstack["keypair"]
  os.ssh_username = openstack["ssh_username"]
  os.endpoint = openstack["endpoint"]
  os.availability_zone  = openstack["availability_zone"]           # optional
  os.api_key  = (ENV['OS_PASSWORD'] || :passwd) # __${username}_passwd__" openstack password"
  if openstack["networks"].nil?
    os.network ="#{os.availability_zone}"
  else
    os.network =openstack["networks"]
  end
  os.networks = [os.network]
  os.metadata  = {"key" => "value"}                      # optional
  os.user_data = "#cloud-config\nmanage_etc_hosts: True" # optional
  os.security_groups    = ['default']    # optional
end

config = env[:machine].env.vagrantfile.config.custom_action.config

puts "pre libvirt create domain!..\n\n".green

if config['provider_network']['config']['mode'] == 'ovs'
  config['provider_network']['config']['ifaces'].each do |iface|
    output = system("sudo ovs-vsctl show|grep \"Bridge #{iface['name']}\"")
    unless output
      puts "sudo ovs-vsctl add-br #{iface['name']}\n\n".green
      system("sudo ovs-vsctl add-br #{iface['name']}\n\n")
    end
    if iface.key?('vlan')
      puts "sudo ovs-vsctl set port #{iface['name']} tag=#{iface['vlan']}".green
      system("sudo ovs-vsctl set port #{iface['name']} tag=#{iface['vlan']}")
    else
      puts "sudo ovs-vsctl clear port #{iface['name']} tag".green
      system("sudo ovs-vsctl clear port #{iface['name']} tag")
    end
    output = system("ifconfig #{iface['name']}|grep 'inet addr' | grep \"#{iface['ip']}\"")
    unless output
      puts "sudo ifconfig #{iface['name']} #{iface['ip']} netmask #{iface['netmask']} up".green
      system("sudo ifconfig #{iface['name']} #{iface['ip']} netmask #{iface['netmask']} up")
    end
  end
elsif config['provider_network']['config']['mode'] == 'bridge'
  config['provider_network']['config']['ifaces'].each do |iface|
    output = system("sudo brctl show|awk '{print $1}'|grep \"#{iface['name']}\"")
    unless output
      puts "sudo brctl addbr #{iface['name']}\n\n".green
      system("sudo brctl addbr #{iface['name']}\n\n")
    end
  end
end

config = env[:machine].env.vagrantfile.config.custom_action.config
h = env[:machine].config.vm.hostname.to_s

puts "post create network....\n\n".green

h = h[0..-'.stack'.length - 1] if h.include? '.stack'

net = config['provider_network']['provider']['management_network_name']

system('sudo touch /etc/dnsmasq.d/stack')
ipexist = `ls -al /var/lib/libvirt/dnsmasq/#{net}.leases 2>/dev/null`
ip = ''
if ipexist != ''
  ip = `sudo cat /var/lib/libvirt/dnsmasq/#{net}.leases | grep #{h} | cut -d' ' -f3`
  ip = ip[0..-2]
else
  ip = `virsh net-dhcp-leases #{net} | grep #{h} | awk '{print $5}'`
  ip = ip.split('/')[0]
end
puts "sudo sed -i \"/#{h}/d\" /etc/dnsmasq.d/stack".green
system("sudo sed -i \"/#{h}/d\" /etc/dnsmasq.d/stack")
puts "echo \"address=/#{h}.stack/#{ip}\" | sudo tee -a /etc/dnsmasq.d/stack".green
system("echo \"address=/#{h}.stack/#{ip}\" | sudo tee -a /etc/dnsmasq.d/stack")

config['provider_network']['config']['endpoints'].each do |endpoint|
  next unless endpoint.key? h

  ep = endpoint[h]
  entries = ''
  ep['entries'].each do |_k, v|
    dns =  v.to_s + '.' + ep['domain']
    puts dns
    puts "sudo sed -i \"/#{dns}/d\" /etc/dnsmasq.d/stack".green
    system("sudo sed -i \"/#{dns}/d\" /etc/dnsmasq.d/stack")
    puts "echo \"address=/#{dns}/#{ip}\" | sudo tee -a /etc/dnsmasq.d/stack".green
    system("echo \"address=/#{dns}/#{ip}\" | sudo tee -a /etc/dnsmasq.d/stack")
    entries += '<hostname>' + dns + '</hostname>'
  end

  exist = `virsh net-dumpxml #{net} | grep -1 #{ep['domain']}`.gsub("\n", '').gsub('    ', '')
  puts exist
  if exist != ''
    puts "virsh net-update #{net} delete dns-host \"#{exist}\"".green
    system("virsh net-update #{net} delete dns-host \"#{exist}\"")
  end
  puts "virsh net-update #{net} add dns-host \"<host ip='#{ip}'>#{entries}</host>\"".green
  system("virsh net-update #{net} add dns-host \"<host ip='#{ip}'>#{entries}</host>\"")
end

puts 'sudo service dnsmasq restart'.green
system('sudo service dnsmasq restart')

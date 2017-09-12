chef_server_url 'http://{{ ansible_eth0.ipv4.address }}:4000'
node_name 'zero-host'
client_key '/tmp/fake_key/fake.pem'
http_proxy "http://proxy.server.io:8080"

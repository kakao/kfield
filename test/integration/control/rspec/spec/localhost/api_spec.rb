require 'spec_helper'

# keystone
describe port(35357) do
  it { should be_listening }
end

# neutron-server
describe port(9696) do
  it { should be_listening }
end

# nova-ec2
describe port(8773) do
  it { should be_listening }
end

# glance-api
describe port(9292) do
  it { should be_listening }
end

# nova-api
describe port(8774) do
  it { should be_listening }
end

# cinder-api
describe port(8776) do
  it { should be_listening }
end

# keystone-admin
describe port(5000) do
  it { should be_listening }
end

# mysql
describe port(3306) do
  it { should be_listening }
end

# memcached
describe port(11211) do
  it { should be_listening }
end

#heat-api
describe port(8004) do
  it { should be_listening }
end

#heat-api-cfn
describe port(8000) do
  it { should be_listening }
end

#heat-api-cloudwatch
describe port(8003) do
  it { should be_listening }
end

# ceilometer-api
describe port(8777) do
  it { should be_listening }
end

#trove-api
describe port(8779) do
  it { should be_listening }
end

# apache2
describe port(80) do
  it { should be_listening }
end

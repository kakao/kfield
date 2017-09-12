default[:trove][:api_workers] = nil
default[:trove][:conductor_workers] = nil
default[:trove][:enabled_databases] = {}

default[:trove][:network_label] = '.*$'

default[:trove][:enabled_databases][:mysql][:version] = %w(
  5.6|Asia/Seoul|utf8mb4
  5.6|Asia/Seoul|utf8
  5.6|UTC|utf8mb4
  5.6|UTC|utf8
)
default[:trove][:enabled_databases][:mysql][:config_enable] = true

default[:trove][:enabled_databases][:redis][:version] = %w(
  2.8
)
default[:trove][:enabled_databases][:redis][:config_enable] = false

default[:trove][:enabled_databases][:mongodb][:version] = %w(
  2.6
)
default[:trove][:enabled_databases][:mongodb][:config_enable] = false

default[:trove][:enabled_databases][:ppas][:version] = %w(
  9.4
)
default[:trove][:enabled_databases][:ppas][:config_enable] = false

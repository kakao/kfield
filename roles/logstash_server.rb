name 'logstash_server'
description 'logstash'
run_list(
     'recipe[logstash::server]'
)

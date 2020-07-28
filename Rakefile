require 'chef/role'
require 'chef/environment'
require 'json'
require 'pp'
require 'fileutils'
require 'rake'

TOPDIR = File.dirname(__FILE__)
ROLE_DIR = File.expand_path(File.join(TOPDIR, "./roles"))
ENVI_DIR = File.expand_path(File.join(TOPDIR, "./environments"))
FileUtils.mkdir_p File.expand_path(File.join(TOPDIR, '.json/environments'))
FileUtils.mkdir_p File.expand_path(File.join(TOPDIR, '.json/roles'))

namespace :convert do
  desc "Convert ruby roles from ruby to json, creating/overwriting json files."
  task :roles4rb2json do
    Dir.glob(File.join(ROLE_DIR, '*.rb')) do |rb_file|
      role = Chef::Role.new
      role.from_file(rb_file)
      json_file = rb_file.sub(/\.rb$/,'.json')
      File.open(json_file, 'w'){|f| f.write(JSON.pretty_generate(JSON.parse(role.to_json)))}
    end
  end
  desc "Convert ruby env from ruby to json, creating/overwriting json files."
  task :envi4rb2json do
    Dir.glob(File.join(ENVI_DIR, '*.rb')) do |rb_file|
      environ = Chef::Environment.new
      environ.from_file(rb_file)
      json_file = rb_file.sub(/\.rb$/,'.json')
      File.open(json_file, 'w'){|f| f.write(JSON.pretty_generate(JSON.parse(environ.to_json)))}
    end
  end
  desc "Convert ruby roles from json to ruby, creating/overwriting rb files."
  task :roles4json2rb do
    Dir.glob(File.join(ROLE_DIR, '*.json')) do |json_file|
      rb_file = json_file.sub(/\.json$/,'.rb')
      File.open(rb_file, 'w'){|f| PP.pp(JSON.parse(IO.read(json_file)), f)}
    end
  end
  desc "Convert ruby env from json to ruby, creating/overwriting rb files."
  task :envi4json2rb do
    Dir.glob(File.join(ENVI_DIR, '*.json')) do |json_file|
      rb_file = json_file.sub(/\.json$/,'.rb')
      File.open(rb_file, 'w'){|f| PP.pp(JSON.parse(IO.read(json_file)), f)}
    end
  end
  desc "Convert DSL from ruby to json, creating/overwriting json files."
  task :rb2json4kfield do
    Dir.glob(File.join(ENVI_DIR, '*.rb')) do |rb_file|
      environ = Chef::Environment.new
      environ.from_file(rb_file)
      json_file = rb_file.sub(/\.rb$/,'.json')
      json_file = json_file.sub(/environments/,'.json/environments')
      File.open(json_file, 'w'){|f| f.write(JSON.pretty_generate(JSON.parse(environ.to_json)))}
    end
    Dir.glob(File.join(ROLE_DIR, '*.rb')) do |rb_file|
      role = Chef::Role.new
      role.from_file(rb_file)
      json_file = rb_file.sub(/\.rb$/,'.json')
      json_file = json_file.sub(/roles/,'.json/roles')
      File.open(json_file, 'w'){|f| f.write(JSON.pretty_generate(JSON.parse(role.to_json)))}
    end
  end
end

namespace :ci do
  task :_worker, :arg1 do |t, args|
    pid = fork {exec(args['arg1']) }
    _, status  = Process.waitpid2(pid)

    if !status.success?
      @error = "task failed"
      exit 1
    end
  end

  desc "create vm for vlan "
  task :create_vlan do
    cmd = "KITCHEN_YAML=./.kitchen.yml kitchen create default-ubuntu-1404 -p && sleep 5"
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  desc "create vm for 32bit test"
  task :create_32bit do
    cmd = "KITCHEN_YAML=./.kitchen.yml kitchen create 32bit-ubuntu-1404 -p && sleep 5"
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  desc "verify_vlan"
  task :verify_vlan do
    puts("About to run Test kitchen ")
    cmd = "KITCHEN_YAML=./.kitchen.yml kitchen converge default-ubuntu-1404"
    cmd << "&&  KITCHEN_YAML=./.kitchen.yml kitchen verify default-ubuntu-1404"
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  desc "verify_32bit"
  task :verify_32bit do
    puts("About to run Test kitchen ")
    cmd = "KITCHEN_YAML=./.kitchen.yml kitchen converge 32bit-ubuntu-1404"
    cmd << "&& KITCHEN_YAML=./.kitchen.yml kitchen verify 32bit-ubuntu-1404"
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  desc "verify vlan system"
  task :verify_vlan_system=>['convert:rb2json4kfield','ci:create_vlan','ci:verify_vlan' ] do
    puts "System configured"
  end

  desc "verify 32bit system"
  task :verify_32bit_system=>['convert:rb2json4kfield','ci:create_32bit','ci:verify_32bit' ] do
    puts "System configured"
  end

  desc "create every vm "
  task :create_vm do
    cmd = "KITCHEN_YAML=./.kitchen_distribute.yml kitchen create 1404 -p "
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  desc "converge database"
  task :converge_db do
    puts("About to run Test kitchen ")
    cmd = "KITCHEN_YAML=./.kitchen_distribute.yml kitchen converge db-ubuntu-1404"
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  task :converge_control do
    puts("About to run Test kitchen ")
    cmd = "KITCHEN_YAML=./.kitchen_distribute.yml kitchen verify control-ubuntu-1404"
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  task :converge_compute do
    puts("About to run Test kitchen ")
    cmd = "KITCHEN_YAML=./.kitchen_distribute.yml kitchen verify compute-ubuntu-1404"
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end

  desc "verify system"
  task :verify_system =>['ci:converge_db','ci:converge_control','ci:converge_compute' ] do
    puts "System configured"
  end

  desc "destroy system"
  task :destroy_system do
    cmd = "KITCHEN_YAML=./.kitchen_distribute.yml kitchen destroy"
    Rake::Task['ci:_worker'].reenable
    Rake::Task['ci:_worker'].invoke(cmd)
  end
end

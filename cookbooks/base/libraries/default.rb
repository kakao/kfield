
def check_environment_production
  ! (check_environment_develop || check_environment_jenkins)
end

def check_environment_test
  (check_environment_develop || check_environment_jenkins || check_environment_stage)
end

def check_environment_develop
  node.chef_environment.start_with? 'devel'
end

def check_environment_jenkins
  node.chef_environment.start_with? 'jenkins'
end

def check_environment_stage
  node.chef_environment.start_with? 'stage'
end

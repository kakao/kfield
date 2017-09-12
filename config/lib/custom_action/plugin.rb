module CustomAction
  require 'vagrant/util/hash_with_indifferent_access'

  require_relative 'action/berks_downloader'
  require_relative 'action/role_env_converter'
  require_relative 'action/post_network'
  require_relative 'action/pre_create_domain'

  def custom_action_config(env)
    env[:machine].env.vagrantfile.config.custom_action.config
  end

  class CustomActionConfig < Vagrant.plugin('2', :config)
    attr_accessor :config
    def initialize
      super
      @config = Hash.new
    end
    def to_hash
      ::Vagrant::Util::HashWithIndifferentAccess.new(instance_variables_hash)
    end
  end

  class CustomActionPlugin < Vagrant.plugin('2')
    name 'custom_action'

    action_hook 'RoleAndEnvConverter' do |hook|
      hook.before VagrantPlugins::ChefZero::Action::Upload, RoleAndEnvConverter
    end

    action_hook 'BerksDownloader' do |hook|
      hook.before VagrantPlugins::Berkshelf::Action::Install, BerksDownloader
    end

    action_hook 'PostCreateNetworkAction' do |hook|
      hook.before VagrantPlugins::ProviderLibvirt::Action::CreateNetworks, PostCreateNetworkAction
    end

    action_hook 'PreCreateDomainAction' do |hook|
      hook.before VagrantPlugins::ProviderLibvirt::Action::CreateDomain, PreCreateDomainAction
    end

    config(:custom_action) do
      CustomActionConfig
    end
  end
end

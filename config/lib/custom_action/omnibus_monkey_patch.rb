require 'vagrant'

module VagrantPlugins
  module Omnibus
    class Config < Vagrant.plugin('2', :config)
      def validate!(machine)
        finalize!
      end
    end
  end
end

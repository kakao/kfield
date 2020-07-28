module CustomAction
  class PostCreateNetworkAction
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)
      cfg_dir = File.expand_path File.dirname(__FILE__)
      case env[:machine].provider_name
      when :libvirt
        instance_eval(IO.read("#{cfg_dir}/../../../post_libvirt_network.rb"))
      end
    end
  end
end

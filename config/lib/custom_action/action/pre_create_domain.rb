module CustomAction
  class PreCreateDomainAction
    def initialize(app, env)
      @app = app
    end

    def call(env)
      cfg_dir = File.expand_path File.dirname(__FILE__)
      case env[:machine].provider_name
      when :libvirt
        instance_eval(IO.read("#{cfg_dir}/../../../pre_libvirt_create_domain.rb"))
      end
      @app.call(env)
    end
  end
end

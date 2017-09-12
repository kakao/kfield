
module CustomAction
  class RoleAndEnvConverter
    def initialize(app, _env)
      @app = app
    end

    def call(env)
      puts "Convert ruby role and environment to json file...\n".green
      gemfile = File.expand_path(
        File.join(
          File.dirname(__FILE__),
          '../../../../Gemfile'))
      system("BUNDLE_GEMFILE=#{gemfile}" \
             ' GEM_PATH=$VAGRANT_OLD_ENV_GEM_PATH' \
             ' PATH=$VAGRANT_OLD_ENV_PATH' \
             ' rake convert:rb2json4kfield')
      @app.call(env)
    end
  end
end

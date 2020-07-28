
module CustomAction
  class BerksDownloader
    def initialize(app, _env)
      @app = app
    end

    def call(env)
      puts "Berks download for caching cookbooks...\n".green
      gemfile = File.expand_path(
        File.join(
          File.dirname(__FILE__),
          '../../../../Gemfile'))
      berksfile = File.expand_path(
        File.join(
          File.dirname(__FILE__),
          '../../../../Berksfile'))
      system("BUNDLE_GEMFILE=#{gemfile}" \
             ' GEM_PATH=$VAGRANT_OLD_ENV_GEM_PATH' \
             ' PATH=$VAGRANT_OLD_ENV_PATH' \
             ' HTTP_PROXY=http://proxy.server.io:8080' \
             ' HTTPS_PROXY=http://proxy.server.io:8080' \
             " berks install -b #{berksfile}")
      @app.call(env)
    end
  end
end

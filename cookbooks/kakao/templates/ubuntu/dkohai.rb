Ohai.plugin(:DKcmdb) do
  require 'net/http'
  require 'uri'
  require 'json'
  provides 'dk'

  cmdb_url = 'http://cmdb-api.your.com'
  cmdb_path = '/cmdb/dns/lookup/'

  def init_dkcmdb
    dk Mash.new
  end

  def from_cmd(cmd)
    so = shell_out(cmd)
    so.stdout.split($RS)[0]
  end

  collect_data(:default) do
    init_dkcmdb
    dk[:devel_region] = 'devel'
    hostname = from_cmd('hostname -s')
    dk[:hostname] = hostname

    uri = cmdb_url + cmdb_path + hostname

    begin
      res = Net::HTTP.get_response(URI.parse(uri))
      if '200' == res.code
        dk[:cmdb] = JSON.parse(res.body)
      else
        dk[:cmdb] = nil
      end
    rescue Exceptions => e
      Ohai::Log.debug("cannot connect to api: #{e}")
    end
  end
end

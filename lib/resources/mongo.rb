class Mongo < Inspec.resource(1)
  name 'mongo'
  supports platform: 'unix'
  
  def initialize(port = 27017, host = '127.0.0.1')
    @port = port
    @host = host
    
    fetch_conf_path
  end
  
  private
  
  def fetch_conf_path
    cmd_string = 'mongo --eval db.runCommand({getCmdLineOpts:1})'
    cmd = inspec.command(cmd_string)
    require 'pry'
    binding.pry
  end
end
# encoding: utf-8

require 'utils/parser'
require 'utils/file_reader'

class SyslogNGConf < Inspec.resource(1)
  name 'syslog_ng_conf'
  supports platform: 'linux'
  desc ''
  example "
    
  "

  attr_reader :params

  include CommentParser
  include FileReader

  DEFAULT_UNIX_PATH = '/etc/syslog-ng/syslog-ng.conf'.freeze

  def initialize(rsyslog_path = nil)
    @path = rsyslog_path || DEFAULT_UNIX_PATH
    content = read_file_content(@path)
    return skip_resource 'The `rsyslog_conf` resource is not supported on Windows.' if inspec.os.windows?
    @params = parse_rsyslog(content)
  end
  
  def selectors
    @params
  end
  
  def sends_to_remote_server(facility, priority, server, port = nil)
    @params.include?({facility: facility, priority: priority, server: server, port: port})
  end
  
  private
  
  def parse_rsyslog(content)
    data = RsyslogConfig.parse(content)
  rescue StandardError => _
    raise "Cannot parse Rsyslog config in #{@path}."
  end
end

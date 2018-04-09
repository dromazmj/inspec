# encoding: utf-8

require 'utils/parser'
require 'utils/file_reader'
require 'utils/rsyslog_parser'

# STABILITY: Experimental
# This resouce needs a proper interace to the underlying data, which is currently missing.
# Until it is added, we will keep it experimental.
class RsyslogConf < Inspec.resource(1)
  name 'rsyslog_conf'
  supports platform: 'linux'
  desc ''
  example "
    
  "

  attr_reader :params

  include CommentParser
  include FileReader

  DEFAULT_UNIX_PATH = '/etc/rsyslog.conf'.freeze

  def initialize(rsyslog_path = nil)
    @path = rsyslog_path || DEFAULT_UNIX_PATH
    content = read_file_content(@path)
    return skip_resource 'The `rsyslog_conf` resource is not supported on Windows.' if inspec.os.windows?
    @selectors = parse_rsyslog(content)
  end
  
  def selectors
    @selectors
  end
  
  def sends_to_remote_server(facility, priority, server, port = nil)
    @selectors.include?({facility: facility, priority: priority, server: server, port: port})
  end
  
  private
  
  def parse_rsyslog(content)
    data = RsyslogConfig.parse(content)
  rescue StandardError => _
    raise "Cannot parse Rsyslog config in #{@path}."
  end
end

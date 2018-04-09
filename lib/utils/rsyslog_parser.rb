# encoding: utf-8
# author: Matthew Dromazos

require 'parslet'

# only designed for sysklogd formatted config files for now:
class RsyslogParser < Parslet::Parser
  root :selectors
  
  rule(:selectors) { selector.repeat }
  
  rule(:selector) {
    (comment |
    local_selector |
    remote_selector | 
    database_selector)  >> 
    newline.repeat
  }
    
  rule(:local_selector) { 
    (facility >> 
    dot >> 
    priority >> 
    space.repeat >> 
    local_destination).as(:local_selector)
  }
  
  rule(:remote_selector) { 
    (facility >> 
    dot >> 
    priority >> 
    space.repeat >> 
    protocol >>
    remote_destination >>
    (colon >>
    port).maybe).as(:remote_selector)
  }
  
  rule(:database_selector) { 
    (facility >> 
    dot >> 
    priority >> 
    space.repeat >> 
    str('>') >>
    dbhost >>
    dbname >>
    dbuser >>
    dbpassword).as(:database_selector)
  }
  
  rule(:protocol) { (str('@').repeat(1,2)).as(:protocol) }
  rule(:local_destination) { (str('@').absent? >> str('>').absent? >> (newline.absent? >> any).repeat).as(:local_destination) }
  rule(:remote_destination) { (((colon.absent? >> newline.absent?) >> any).repeat).as(:remote_destination) }
  rule(:facility) { ((dot.absent? >> any).repeat).as(:facility) }
  rule(:priority) { ((space.absent? >> any).repeat).as(:priority) }
  rule(:port) { (((newline.absent? >> semicolon.absent?) >> match['0-9']).repeat).as(:port) }
  rule(:comment) { str('#') >> (match["\n\r"].absent? >> any).repeat }
  
  # Rules for database selectors
  rule(:dbhost) { ((comma.absent? >> any).repeat).as(:dbhost) >> comma }
  rule(:dbname) { ((comma.absent? >> any).repeat).as(:dbname) >> comma }
  rule(:dbuser) { ((comma.absent? >> any).repeat).as(:dbuser) >> comma }
  rule(:dbpassword) { ((newline.absent? >> any).repeat).as(:dbpassword) }


  rule(:space)   { match('\s+') }
  rule(:newline) { match['\n'] }
  rule(:dot) { str('.') }
  rule(:comma) { str(',') }
  rule(:colon) { str(':') }
  rule(:semicolon) { str(';') }

end

class RsyslogTransform < Parslet::Transform
  rule(local_selector: subtree(:local_selector)) { {
    local_selector: {facility: local_selector[:facility].to_s, 
      priority: local_selector[:priority].to_s, 
      destination: local_selector[:local_destination].to_s} } }
  
  rule(remote_selector: subtree(:remote_selector)) { {
    remote_selector: {facility: remote_selector[:facility].to_s, 
      priority: remote_selector[:priority].to_s, 
      protocol: remote_selector[:protocol].to_s,
      destination: remote_selector[:remote_destination].to_s} } }
  
  rule(remote_selector: subtree(:remote_selector)) { {
    remote_selector: {facility: remote_selector[:facility].to_s, 
      priority: remote_selector[:priority].to_s, 
      protocol: remote_selector[:protocol].to_s,
      destination: remote_selector[:remote_destination].to_s, 
      port: remote_selector[:port].to_s,} } }
  
  rule(database_selector: subtree(:database_selector)) { {
    database_selector: {facility: database_selector[:facility].to_s, 
      priority: database_selector[:priority].to_s, 
      dbhost: database_selector[:dbhost].to_s, 
      dbname: database_selector[:dbname].to_s, 
      dbuser: database_selector[:dbuser].to_s, 
      dbpassword: database_selector[:dbpassword].to_s} } }
end

class RsyslogConfig
  def self.parse(content)
    lex = RsyslogParser.new.parse(content)
    tree = RsyslogTransform.new.apply(lex)
    group_selectors(tree)
  rescue Parslet::ParseFailed => err
    puts err.parse_failure_cause.ascii_tree
    raise "Failed to parse Rsyslog config: #{err}"
  end
  
  def self.group_selectors(tree)
    selectors = {
      local_selectors: [],
      remote_selectors: [],
      database_selectors: [],
    }
    tree.each do |selector|
      selectors[:local_selectors] << selector[:local_selector] if selector[:local_selector]
      selectors[:remote_selectors] << selector[:remote_selector] if selector[:remote_selector]
      selectors[:database_selectors] << selector[:database_selector] if selector[:database_selector]
    end
    selectors
  end
    
end

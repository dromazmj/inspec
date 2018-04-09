# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'parslet'

class SyslogNGParser < Parslet::Parser
  root :outermost
  # only designed for rabbitmq config files for now:
  rule(:outermost) { filler? >> section.repeat }

  rule(:filler?) { one_filler.repeat }
  rule(:one_filler) { match('\s+') | match["\n"] | comment }
  rule(:space)   { match('\s+') }
  rule(:comment) { str('#') >> (match["\n\r"].absent? >> any).repeat }

  rule(:option) {
    (identifier >> values.maybe.as(:args)).as(:assignment) >> str(';') >> filler?
  }

  rule(:standard_identifier) {
    (match('[a-zA-Z]') >> match('\S').repeat).as(:identifier) >> space >> space.repeat
  }

  rule(:quoted_identifier) {
    str('"') >> (str('"').absent? >> any).repeat.as(:identifier) >> str('"') >> space.repeat
  }

  rule(:identifier) {
    standard_identifier | quoted_identifier
  }

  rule(:value) {
    ((match('[#;{]').absent? >> any) >> (
      str('\\') >> any | match('[#;{]|\s').absent? >> any
    ).repeat).as(:value) >> space.repeat
  }

  rule(:values) {
    value.repeat >> space.maybe
  }
  
  rule(:type) {
    str('source') |
    str('destination') | 
    str('log') |
    str('filter') |
    str('parser') |
    str('rewrite') |
    str('template')
  }

  rule(:section) {
    type.as(:section) >> identifier.maybe.as(:identifier) >> str('{') >> filler? >> option.repeat.as(:expressions) >> str('};') >> filler?
  }
end

class SyslogNGTransform < Parslet::Transform
  Group = Struct.new(:type, :id, :body)
  Exp = Struct.new(:key, :vals)

  rule(section: { identifier: simple(:x) }, args: subtree(:y), expressions: subtree(:z)) { Group.new(x.to_s, y, z) }
  rule(option: { identifier: simple(:x), args: subtree(:y) }) { Exp.new(x.to_s, y) }
  rule(value: simple(:x)) { x.to_s }
end

class SyslogNGConfig
  def self.parse(content)
    lex = SyslogNGParser.new.parse(content)
    tree = SyslogNGTransform.new.apply(lex)
  rescue Parslet::ParseFailed => err
    puts err.parse_failure_cause.ascii_tree
    raise "Failed to parse Syslog-NG config: #{err}"
  end
end

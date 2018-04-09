# encoding: utf-8

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Rsyslog' do
  let(:rsyslog_conf) { load_resource('rsyslog_conf') }

  it 'reads the rsyslog_cong with all referenced include calls' do
    _(rsyslog_conf.selectors).must_be_kind_of Hash

    # verify parses local selector
    _(rsyslog_conf.selectors[:local_selectors]).must_include({facility: 'kern', priority: '*', destination: '/var/adm/kernel'})

    # verify parses local selector
    _(rsyslog_conf.selectors[:remote_selectors]).must_include({facility: '*', priority: '*', protocol: '@@', destination: 'finlandia', port: '1514'})
    
    # verify parses local selector
    _(rsyslog_conf.selectors[:database_selectors]).must_include({facility: '*', priority: '*', dbhost: 'dbhost', dbname: 'dbname', dbuser: 'dbuser', dbpassword: 'dbpassword'})
    # {:facility=>"*", :priority=>"*", :dbhost=>"dbhost,", :dbname=>"dbname,", :dbuser=>"dbuser,", :dbpassword=>"dbpassword"}}

  end
  
  # it 'skips the resource if it cannot parse the config' do
  #   resource = MockLoader.new(:ubuntu1404).load_resource('nginx_conf', '/etc/nginx/failed.conf')
  #   _(resource.params).must_equal({})
  #   _(resource.resource_exception_message).must_equal "Cannot parse NginX config in /etc/nginx/failed.conf."
  # end
end

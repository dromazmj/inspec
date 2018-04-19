# encoding: utf-8

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::Rsyslog' do  
  describe 'RsyslogConf Paramaters' do
    rsyslog_conf = load_resource('rsyslog_conf')
    it 'Verify rsyslog_conf property sending_to_remote_server'  do
      _(rsyslog_conf.sending_to_remote_server).must_equal true
    end
    
    it 'Verify rsyslog_conf filtering by `selector_type` local'  do
      entries = rsyslog_conf.where { selector_type == 'local' }
      _(entries.facilities).must_equal ['*', 'kern', 'kern', 'kern'] 
      _(entries.priorities).must_equal ['=crit', '*', 'crit', 'info']
      _(entries.destinations).must_equal ['/var/adm/critical', '/var/adm/kernel', '/dev/console', '/var/adm/kernel-info']
    end
    it 'Verify rsyslog_conf filtering by `selector_type` remote'  do
      entries = rsyslog_conf.where { selector_type == 'remote' }
      _(entries.facilities).must_equal ['kern', '*', '*']
      _(entries.priorities).must_equal ['crit', '*', '*']
      _(entries.protocols).must_equal ['udp', 'tcp', 'udp']
      _(entries.destinations).must_equal ['finlandia', 'finlandia', 'finlandia']
      _(entries.ports).must_include '1514'
    end
    it 'Verify rsyslog_conf filtering by `selector_type` database'  do
      entries = rsyslog_conf.where { selector_type == 'database' }
      _(entries.facilities).must_equal ['*']
      _(entries.priorities).must_equal ['*']
      _(entries.dbhosts).must_equal ['dbhost']
      _(entries.dbnames).must_equal ['dbname']
      _(entries.dbusers).must_equal ['dbuser']
      _(entries.dbpasswords).must_equal ['dbpassword']
    end
  end
end

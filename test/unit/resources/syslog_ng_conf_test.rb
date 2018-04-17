# encoding: utf-8
# author: Matthew Dromazos

require 'helper'
require 'inspec/resource'

describe 'Inspec::Resources::SyslogNGConf' do
  # None of these tests currently work correctly on windows. See the
  # nginx_conf toplevel comment.
  next if Gem.win_platform?

  let(:syslog_ng_conf) { MockLoader.new(:ubuntu1404).load_resource('syslog_ng_conf', '/etc/syslog-ng/syslog-ng.conf') }

  # it 'doesnt fail with a missing file' do
  #   syslog_ng_conf = MockLoader.new(:ubuntu1404).load_resource('syslog_ng_conf', '/....missing_file')
  #   _(syslog_ng_conf.params).must_equal({})
  # end
  # 
  # it 'doesnt fail with an incorrect file' do
  #   syslog_ng_conf = MockLoader.new(:ubuntu1404).load_resource('syslog_ng_conf', '/etc/syslog-ng/syslog-ng.conf')
  #   _(syslog_ng_conf.params).must_equal({})
  # end

  it 'reads the syslog_ng_conf with all referenced include calls' do
    syslog_ng_conf = MockLoader.new(:ubuntu1404).load_resource('syslog_ng_conf', '/etc/syslog-ng/syslog-ng.conf')
    _(syslog_ng_conf.params).must_be_kind_of Array
    
    # verify user
    _(syslog_ng_conf.sending_to_remote_server).must_equal true # multiple
  end
end
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'test_helper'

ENV['RACK_ENV'] = 'test'

require 'smart_proxy_onboard'
require 'bmc/sdr_cache'

class SmartProxyOnboardSDRCacheTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @sdr_cache = ::Proxy::Onboard::BMC::SDRCache.new
  end

  def test_get_sdr_cache_directory_from_freeipmi_conf
    mock_file = [
      'sdr-cache-directory /1',
      "  \t sdr-cache-directory /2",
      "\t \t  sdr-cache-directory    \t /1 2 3",
      '\t \t  sdr-cache-directory    \t /dont-hurt-me'
    ]
    File.expects(:open).with { |*args| args[0] == '/etc/freeipmi/freeipmi.conf' }.returns mock_file
    assert_equal '/1 2 3', @sdr_cache.send(:sdr_cache_directory_from_freeipmi_conf)
  end

  def test_get_sdr_cache_directory_from_inaccessible_freeipmi_conf_returns_nil
    File.expects(:open).raises(Errno::EPERM)
    assert_nil @sdr_cache.send(:sdr_cache_directory_from_freeipmi_conf)
  end

  def test_get_unconfigured_sdr_cache_directory_from_freeipmi_conf_returns_nil
    mock_file = ['nope', 'nothing', '# sdr-cache-directory /my/sdr/path', 'lolnope']
    File.expects(:open).returns mock_file
    assert_nil @sdr_cache.send(:sdr_cache_directory_from_freeipmi_conf)
  end

  def test_possible_paths_returns_expected_values
    mock_user = 'my-user'
    mock_dir  = '/home3/my-user'
    mock_etc_passwd = Etc::Passwd.new(mock_user, nil, nil, nil, nil, mock_dir, nil)
    @sdr_cache.expects(:sdr_cache_directory_from_freeipmi_conf).returns '/1 2 3'
    Etc.expects(:getpwuid).returns mock_etc_passwd
    result = @sdr_cache.possible_paths
    assert result.is_a? Array
    assert_equal 3, result.length
    assert result.include?('/1 2 3')
    assert result.include?("#{mock_dir}/.freeipmi/sdr-cache")
    assert result.include?("/tmp/.freeipmi-#{mock_user}/.freeipmi/sdr-cache")
  end

  def test_existing_possible_paths_returns_expected_values
    mock_paths = ['/1', '/2', '/3']
    File.expects(:exist?).times(mock_paths.length).returns(true, false, true)
    @sdr_cache.expects(:possible_paths).returns(mock_paths)
    result = @sdr_cache.existing_possible_paths
    assert result.is_a? Array
    assert_empty result - mock_paths
    assert_equal 2, result.length
    assert result.include?('/1')
    assert_false result.include?('/2')
    assert result.include?('/3')
  end

  def test_should_be_present
    @sdr_cache.expects(:existing_possible_paths).returns ['/foo/bar']
    assert @sdr_cache.present?
  end

  def test_should_not_be_present
    @sdr_cache.expects(:existing_possible_paths).returns []
    assert_false @sdr_cache.present?
  end

  def test_should_delete
    mock_paths = ['/1', '/2', '/3']
    @sdr_cache.expects(:existing_possible_paths).returns mock_paths
    FileUtils.expects(:remove_entry_secure).times(mock_paths.length).returns([], []).then.raises(Errno::ENOENT)
    result = @sdr_cache.delete
    assert result
  end

  def test_fail_delete
    mock_paths = ['/1', '/2', '/3']
    @sdr_cache.expects(:existing_possible_paths).returns mock_paths
    FileUtils.expects(:remove_entry_secure).times(mock_paths.length).returns([]).then.raises(Errno::ENOENT).then.raises(Errno::EPERM)
    result = @sdr_cache.delete
    assert result.is_a? Hash
    assert result[:errors].is_a? Array
    assert_equal 1, result[:errors].length
  end
end

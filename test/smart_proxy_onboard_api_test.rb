$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'test_helper'

ENV['RACK_ENV'] = 'test'

require 'smart_proxy_onboard'
require 'smart_proxy_onboard/api_bmc'
require 'bmc/ipmiscanner'

class SmartProxyOnboardApiBmcTest < Test::Unit::TestCase
  include Rack::Test::Methods

  attr_reader :host, :args

  def app
    Proxy::Onboard::ApiBmc.new
  end

  def setup
    user     ||= ENV["ipmiuser"] || "user"
    pass     ||= ENV["ipmipass"] || "pass"
    @host    ||= ENV["ipmihost"] || "host"
    provider ||= ENV["ipmiprovider"] || "ipmitool"
    @args    = { 'bmc_provider' => provider, 'blah' => 'test' }
    authorize user, pass
  end

# /scan
  def test_api_scan_can_get_resources
    get "/scan", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    expected = ['range', 'cidr']
    assert_equal(expected, data["available_resources"])
  end

# /scan/range
  def test_api_scan_range_returns_help
    get "/scan/range", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/You need to supply a range/, data["message"])
  end

  def test_api_scan_range_returns_error_when_invalid_first_address_provided
    get "/scan/range/bogus/192.168.1.254", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/nvalid IP address provided/, data["error"])
  end

  def test_api_scan_range_returns_error_when_no_second_address_provided
    get "/scan/range/192.168.1.1", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/nvalid IP address provided/, data["error"])
  end

  def test_api_scan_range_returns_error_when_invalid_last_address_provided
    get "/scan/range/192.168.1.1/bogus", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/nvalid IP address provided/, data["error"])
  end

  def test_api_scan_range_returns_error_when_range_too_large
    Proxy::Onboard::Plugin.settings.expects(:bmc_scanner_max_range_size).returns(256)
    Proxy::Onboard::BMC::IPMIScanner.any_instance.stubs(:scan_to_list).returns([])
    get "/scan/range/15.0.0.0/16.255.255.255", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/too large/, data["error"])
  end
  
  def test_api_scan_range_returns_list_when_valid_range_provided
    Proxy::Onboard::BMC::IPMIScanner.any_instance.expects(:scan_to_list).returns(['192.168.1.5', '192.168.1.10', '192.168.1.253'])
    get "/scan/range/192.168.1.0/192.168.1.254", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_equal(data['result'].length, 3)
    assert_send([data['result'], :include?, '192.168.1.5'])
    assert_send([data['result'], :include?, '192.168.1.10'])
    assert_send([data['result'], :include?, '192.168.1.253'])
  end

  def test_api_scan_range_returns_empty_list_when_scanner_returns_empty_list
    Proxy::Onboard::BMC::IPMIScanner.any_instance.expects(:scan_to_list).returns([])
    get "/scan/range/192.168.1.0/192.168.1.254", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_equal(data['result'].length, 0)
  end

# /scan/cidr
  def test_api_scan_cidr_returns_help
    get "/scan/cidr", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/You need to supply a CIDR/, data["message"])
  end

  def test_api_scan_cidr_returns_error_when_invalid_address_provided
    get "/scan/cidr/bogus/24", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/nvalid CIDR provided/, data["error"])
  end

  def test_api_scan_cidr_returns_error_when_invalid_netmask_provided
    get "/scan/cidr/192.168.1.1/bogus", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/nvalid CIDR provided/, data["error"])
  end

  def test_api_scan_cidr_works_with_single_ip
    Proxy::Onboard::BMC::IPMIScanner.any_instance.expects(:scan_to_list).returns(['192.168.1.1'])
    get "/scan/cidr/192.168.1.1", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_equal(data['result'].length, 1)
    assert_send([data['result'], :include?, '192.168.1.1'])
  end

  def test_api_scan_cidr_returns_error_when_range_too_large
    Proxy::Onboard::Plugin.settings.expects(:bmc_scanner_max_range_size).returns(256)
    Proxy::Onboard::BMC::IPMIScanner.any_instance.stubs(:scan_to_list).returns([])
    get "/scan/cidr/15.0.0.0/8", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_match(/too large/, data["error"])
  end
  
  def test_api_scan_cidr_returns_list_when_prefixlen_range_provided
    Proxy::Onboard::BMC::IPMIScanner.any_instance.expects(:scan_to_list).returns(['192.168.1.5', '192.168.1.10', '192.168.1.253'])
    get "/scan/cidr/192.168.1.0/24", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_equal(data['result'].length, 3)
    assert_send([data['result'], :include?, '192.168.1.5'])
    assert_send([data['result'], :include?, '192.168.1.10'])
    assert_send([data['result'], :include?, '192.168.1.253'])
  end

  def test_api_scan_cidr_returns_list_when_dotdecimal_range_provided
    Proxy::Onboard::BMC::IPMIScanner.any_instance.expects(:scan_to_list).returns(['192.168.1.5', '192.168.1.10', '192.168.1.253'])
    get "/scan/cidr/192.168.1.0/255.255.255.0", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_equal(data['result'].length, 3)
    assert_send([data['result'], :include?, '192.168.1.5'])
    assert_send([data['result'], :include?, '192.168.1.10'])
    assert_send([data['result'], :include?, '192.168.1.253'])
  end

  def test_api_scan_cidr_returns_empty_list_when_scanner_returns_empty_list
    Proxy::Onboard::BMC::IPMIScanner.any_instance.expects(:scan_to_list).returns([])
    get "/scan/cidr/192.168.1.0/255.255.255.0", args
    assert last_response.ok?, "Last response was not ok"
    data = JSON.parse(last_response.body)
    assert_equal(data['result'].length, 0)
  end
end

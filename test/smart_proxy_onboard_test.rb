$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'test_helper'

ENV['RACK_ENV'] = 'test'

require 'smart_proxy_onboard'

class SmartProxyOnboardTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def test_that_it_has_a_version_number
    refute_nil ::Proxy::Onboard::VERSION
  end
end

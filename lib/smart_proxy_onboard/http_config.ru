require 'smart_proxy_onboard/api_bmc'

map '/bmc' do
  run Proxy::Onboard::ApiBmc.new
end

module Proxy
  module Onboard
    # Plugin definition
    class Plugin < ::Proxy::Plugin
      plugin :onboard, Proxy::Onboard::VERSION
      default_settings bmc_scanner_max_range_size: 65_536,
                       bmc_scanner_max_threads_per_request: 500,
                       bmc_scanner_socket_timeout_seconds: 1

      http_rackup_path File.expand_path('http_config.ru', File.expand_path('../', __FILE__))
      https_rackup_path File.expand_path('http_config.ru', File.expand_path('../', __FILE__))
      default_settings node_scheme: 'https', node_port: 8443
    end
  end
end

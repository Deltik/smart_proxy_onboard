require 'smart_proxy'
require 'bmc/ipmiscanner'
require 'bmc/sdr_cache'

module Proxy
  module Onboard
    class ApiBmc < Sinatra::Base
      helpers ::Proxy::Helpers

      # Scan IP range for BMC hosts
      # Returns a list of available scanning options
      get '/scan' do
        { available_resources: %w[range cidr] }.to_json
      end

      # Returns a helpful message that the user should supply a beginning IP and ending IP
      get '/scan/range' do
        { message: 'You need to supply a range with /onboard/bmc/scan/range/:address_first/:address_last' }.to_json
      end

      # Returns a helpful message that the user should supply a CIDR
      get '/scan/cidr' do
        { message: 'You need to supply a CIDR with /onboard/bmc/scan/cidr/:address/:netmask (e.g. "192.168.1.1/24" or "192.168.1.1/255.255.255.0")' }.to_json
      end

      ['/scan/range/:address_first/?:address_last?',
       '/scan/cidr/:address/?:netmask?'].each do |path|
        get path do
          scanner_setup
          if !@scanner.valid?
            { error: @scanner.error_string }.to_json
          else
            { result: @scanner.scan_to_list }.to_json
          end
        end
      end

      def scanner_setup
        args = {}
        # /scan/cidr/:address/:netmask
        if params.key? 'address'
          args = { address: params[:address],
                   netmask: params[:netmask] }
        # /scan/range/:address_first/:address_last
        elsif params.key? 'address_first'
          args = { address_first: params[:address_first],
                   address_last: params[:address_last] }
        end
        @scanner = Proxy::Onboard::BMC::IPMIScanner.new(args)
      end

      # Clear the SDR cache
      delete '/sdr_cache' do
        sdr_cache = Proxy::Onboard::BMC::SDRCache.new
        return { result: true, message: 'No SDR cache to delete' }.to_json unless sdr_cache.present?
        result = sdr_cache.delete
        return result.merge(result: false, message: 'Failed to delete one or more SDR cache location candidates').to_json if result.is_a? Hash
        return { result: true, message: 'SDR cache deleted' }.to_json if result == true
        return { result: false, message: 'Unexpected response from delete function' }.to_json
      end
    end
  end
end

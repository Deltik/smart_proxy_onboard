require 'smart_proxy_onboard'
require 'fileutils'

module Proxy
  module Onboard
    module BMC
      class SDRCache
        include Proxy::Log
        include Proxy::Util

        # Determined from
        # https://git.savannah.gnu.org/cgit/freeipmi.git/tree/common/toolcommon/tool-sdr-cache-common.c?h=Release-1_4_11
        def possible_paths
          paths = []
          sdr_cache_directory = sdr_cache_directory_from_freeipmi_conf
          paths << sdr_cache_directory unless sdr_cache_directory.nil?
          etc = Etc.getpwuid(Process.uid)
          paths + [
            "#{etc.dir}/.freeipmi/sdr-cache",
            "/tmp/.freeipmi-#{etc.name}/.freeipmi/sdr-cache"
          ]
        end

        def existing_possible_paths
          paths = []
          possible_paths.each do |path|
            paths << path if File.exist?(path)
          end
          paths
        end

        def present?
          !existing_possible_paths.empty?
        end

        def delete
          errors = []
          existing_possible_paths.each do |path|
            begin
              FileUtils.remove_entry_secure(path)
            rescue Errno::ENOENT
              next
            rescue SystemCallError => e
              errors << e
              next
            end
          end
          return { errors: errors } unless errors.empty?
          true
        end

        private

        def sdr_cache_directory_from_freeipmi_conf
          freeipmi_conf_handle = File.open('/etc/freeipmi/freeipmi.conf', 'r')
          match = %r{^[[:blank:]]*sdr-cache-directory[[:blank:]]+\/}
          freeipmi_conf_handle.grep(match).last.gsub(match, '/').gsub(/\n$/, '')
        rescue SystemCallError
          logger.debug 'Cannot determine sdr-cache-directory from FreeIPMI configuration file'
          nil
        rescue NoMethodError
          logger.debug 'FreeIPMI configuration file does not contain sdr-cache-directory'
          nil
        end
      end
    end
  end
end

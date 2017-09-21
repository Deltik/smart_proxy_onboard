require 'smart_proxy_onboard'
require 'fileutils'

module Proxy
  module Onboard
    module BMC
      class SDRCache

        # Determined from
        # https://git.savannah.gnu.org/cgit/freeipmi.git/tree/common/toolcommon/tool-sdr-cache-common.c?h=Release-1_4_11
        def possible_paths
          paths = []
          begin
            freeipmi_conf_handle = File.open('/etc/freeipmi/freeipmi.conf', 'r')
            match = /^[[:blank:]]*sdr-cache-directory[[:blank:]]+\//
            paths << freeipmi_conf_handle.grep(match).last.gsub(match, '/').gsub(/\n$/, '')
          rescue SystemCallError
          end
          etc = Etc.getpwuid(Process.uid)
          paths + [
            "#{etc.dir}/.freeipmi/sdr-cache",
            "/tmp/.freeipmi-#{etc.name}/.freeipmi/sdr-cache",
          ]
        end

        def existing_possible_paths
          paths = []
          self.possible_paths.each do |path|
            paths << path if File.exist?(path)
          end
          paths
        end

        def present?
          !self.existing_possible_paths.empty?
        end

        def delete
          errors = []
          self.existing_possible_paths.each do |path|
            begin
              FileUtils.remove_entry_secure(path)
            rescue Errno::ENOENT
            rescue SystemCallError => e
              errors << e
            end
          end
          return { errors: errors } unless errors.empty?
          true
        end

      end
    end
  end
end


lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smart_proxy_onboard/version'

Gem::Specification.new do |spec|
  spec.name          = 'smart_proxy_onboard'
  spec.version       = Proxy::Onboard::VERSION
  spec.authors       = ['Nick Liu']
  spec.email         = ['deltik@gmx.com']

  spec.summary       = 'Support functions for onboarding new servers into Foreman'
  spec.description   = 'This plugin exposes API calls that can be used to onboard new hosts in bulk into Foreman through PXE boot and the foreman_discovery image.'
  spec.homepage      = 'https://github.com/theforeman/smart_proxy_onboard'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.license       = 'GPL-3.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'rack'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'webmock'

  spec.add_runtime_dependency 'concurrent-ruby'
end

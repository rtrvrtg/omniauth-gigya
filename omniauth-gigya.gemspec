# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/gigya/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-gigya"
  spec.version       = Omniauth::Gigya::VERSION
  spec.authors       = ["Adam Wilson"]
  spec.email         = ["adam@callawaywilson.com"]
  spec.description   = %q{An Omniauth provider for Gigya OAuth functionality}
  spec.summary       = %q{Omniauth Gigya Provider}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'gigya_api', '~> 0.0.2'
  spec.add_dependency 'omniauth', '~> 1.1'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
end

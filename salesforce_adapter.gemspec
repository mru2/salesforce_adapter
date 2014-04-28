# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salesforce_adapter/version'

Gem::Specification.new do |spec|
  spec.name          = "salesforce_adapter"
  spec.version       = SalesforceAdapter::VERSION
  spec.authors       = ["ClicRDV"]
  spec.email         = ["david.ruyer@clicrdv.com"]
  spec.summary       = %q{Lightweight client for the salesforce API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir['README.md', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rforce", ">= 0.11"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end

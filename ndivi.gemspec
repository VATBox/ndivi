# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ndivi/version'

Gem::Specification.new do |spec|
  spec.name          = "ndivi"
  spec.version       = Ndivi::VERSION
  spec.authors       = ["galharth"]
  spec.email         = ["TODO: Write your email address"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "ya2yaml"
  spec.add_runtime_dependency 'cssmin'
  spec.add_runtime_dependency 'jsmin'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'html_truncator'
  spec.add_runtime_dependency 'ya2yaml'
  spec.add_runtime_dependency 'logging'

end

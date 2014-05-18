# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'ribhu/version'

Gem::Specification.new do |spec|
  spec.name          = "ribhu"
  spec.version       = "0.0.9"
  spec.authors       = ["Rahul Kumar"]
  spec.email         = ["sentinel1879@gmail.com"]
  spec.description   = %q{ri documentation browser using ncurses}
  spec.summary       = %q{ri documentation browser using ncurses}
  spec.homepage      = "https://github.com/rkumar/ribhu"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "rbcurse-core", ">= 0.0.11"
end

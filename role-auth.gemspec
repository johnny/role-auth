# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'role-auth/version'

Gem::Specification.new do |spec|
  spec.name          = "role-auth"
  spec.version       = RoleAuth::VERSION
  spec.authors       = ["Jonas von Andrian"]
  spec.email         = ["jvadev@gmail.com"]
  spec.description   = %q{Rolebased authorization}
  spec.summary       = %q{Compatible with dm and merb. Compiles into Ruby statements}
  spec.homepage      = "http://github.com/johnny/role-auth"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "dm-core"
  spec.add_development_dependency "dm-migrations"
  spec.add_development_dependency "dm-sqlite-adapter"
  spec.add_development_dependency "do_sqlite3"
end
